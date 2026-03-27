using Test
using TransientBrokerage
using StableRNGs: StableRNG
using LinearAlgebra: dot
using Statistics: var

@testset "Phase 1: Matching Function" begin
    d, rho, K_mu = 8, 0.50, 10

    # generate_matching_function returns a valid MatchingEnv with correct dimensions
    @testset "Construction and dimensions" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        @test env.d == d
        @test size(env.mu_centers) == (d, K_mu)
        @test length(env.mu_weights) == K_mu
        @test env.mu_bandwidth > 0.0
    end

    # Variance calibration: Var(mu)/Var(f) approx rho within 25% tolerance
    @testset "Variance calibration Var(mu)/Var(f) approx rho" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        cal_rng = StableRNG(99)
        n = 10_000
        mu_vals = Vector{Float64}(undef, n)
        f_vals = Vector{Float64}(undef, n)
        for i in 1:n
            w = clamp.(randn(cal_rng, d), -3.0, 3.0)
            x = clamp.(randn(cal_rng, d), -3.0, 3.0)
            mu_vals[i] = eval_mu(w, env)
            f_vals[i] = match_output_noiseless(w, x, env)
        end
        var_mu = var(mu_vals)
        var_f = var(f_vals) + 1.0  # add noise variance
        ratio = var_mu / var_f
        @test abs(ratio - rho) / rho < 0.25
    end

    # When rho=0, mu contributes nothing
    @testset "rho=0 zeroes mu weights" begin
        env0 = generate_matching_function(d, 0.0, K_mu, StableRNG(42))
        @test all(env0.mu_weights .== 0.0)
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        @test eval_mu(w, env0) == 0.0
    end

    # Noiseless output equals mu(w) + w'x exactly
    @testset "Decomposition: noiseless = mu + w'x" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        test_rng = StableRNG(77)
        @test all(1:20) do _
            w = clamp.(randn(test_rng, d), -3.0, 3.0)
            x = clamp.(randn(test_rng, d), -3.0, 3.0)
            match_output_noiseless(w, x, env) ≈ eval_mu(w, env) + dot(w, x)
        end
    end

    # Nearby workers produce similar mu values (smoothness)
    @testset "eval_mu smoothness" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        w_near = clamp.(w .+ randn(StableRNG(2), d) .* 0.01, -3.0, 3.0)
        @test abs(eval_mu(w, env) - eval_mu(w_near, env)) < 0.5
    end

    # mu is non-negative (all weights are squared)
    @testset "mu non-negative" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        rng = StableRNG(99)
        @test all(eval_mu(clamp.(randn(rng, d), -3.0, 3.0), env) >= 0.0 for _ in 1:100)
    end

    # calibrate_output_scale returns f_mean and r_base with correct relationship
    @testset "calibrate_output_scale" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        curve = generate_firm_curve(d, StableRNG(10))
        ftypes = generate_firm_types(curve, 50, d, StableRNG(11))
        f_mean, r_base = calibrate_output_scale(env, ftypes, StableRNG(55))
        @test f_mean > 0.0
        @test r_base > 0.0
        @test r_base ≈ 0.60 * f_mean
    end

    # Same seed produces identical output
    @testset "Seed determinism" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        q1 = match_output(w, x, env, StableRNG(10))
        q2 = match_output(w, x, env, StableRNG(10))
        @test q1 == q2
    end

    # Independent MC check of f_bar using same firm types as calibration
    @testset "Statistical consistency of f_bar" begin
        env = generate_matching_function(d, rho, K_mu, StableRNG(42))
        curve = generate_firm_curve(d, StableRNG(10))
        ftypes = generate_firm_types(curve, 50, d, StableRNG(11))
        f_bar, _ = calibrate_output_scale(env, ftypes, StableRNG(55))
        check_rng = StableRNG(200)
        n_f = length(ftypes)
        total = 0.0
        n = 10_000
        for _ in 1:n
            x = ftypes[rand(check_rng, 1:n_f)]
            w = clamp.(x .+ randn(check_rng, d), -3.0, 3.0)
            total += abs(match_output_noiseless(w, x, env))
        end
        f_bar_check = total / n
        @test abs(f_bar_check - f_bar) / f_bar < 0.10
    end

    # End-to-end: generate, evaluate, calibrate, all outputs finite
    @testset "Smoke test (Phase 1)" begin
        p = default_params()
        env = generate_matching_function(p.d, p.rho, p.K_mu, StableRNG(p.seed))
        w = clamp.(randn(StableRNG(1), p.d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(2), p.d), -3.0, 3.0)
        q = match_output(w, x, env, StableRNG(3))
        @test isfinite(q)
        curve = generate_firm_curve(p.d, StableRNG(10))
        ftypes = generate_firm_types(curve, 50, p.d, StableRNG(11))
        f_mean, r_base = calibrate_output_scale(env, ftypes, StableRNG(4))
        @test isfinite(f_mean)
        @test 0.0 < r_base < f_mean
    end
end
