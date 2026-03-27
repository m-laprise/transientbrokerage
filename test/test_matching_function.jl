using Test
using TransientBrokerage
using StableRNGs: StableRNG
using LinearAlgebra: svdvals, norm, dot, mul!
using Statistics: var

@testset "Phase 1: Matching Function" begin
    rng = StableRNG(123)
    d, s, rho, K_mu = 8, 2, 0.50, 10

    # generate_matching_function returns a valid MatchingEnv with correct dimensions
    @testset "Construction and dimensions" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        @test size(env.A) == (d, d)
        @test size(env.U) == (d, s)
        @test size(env.P) == (s, d)
        @test size(env.mu_centers) == (s, K_mu)
        @test length(env.mu_weights) == K_mu
        @test env.mu_bandwidth > 0.0
    end

    # A has exactly rank s (only s non-negligible singular values)
    @testset "Rank of A == s" begin
        env = generate_matching_function(5, 2, 0.50, 10, StableRNG(42))
        svals = svdvals(env.A)
        @test count(s -> s > 1e-10, svals) == 2
    end

    # A is diagonal: A[i,i] = 1 for i <= s, 0 elsewhere
    @testset "A is diagonal" begin
        env = generate_matching_function(8, 2, 0.50, 10, StableRNG(42))
        for i in 1:8, j in 1:8
            if i == j && i <= 2
                @test env.A[i, j] ≈ 1.0
            else
                @test abs(env.A[i, j]) < 1e-10
            end
        end
    end

    # P is orthogonal to U (disjoint subspaces for quality vs. interaction)
    @testset "P-U orthogonality" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        @test norm(env.P * env.U) < 1e-10
    end

    # Variance calibration: Var(μ)/Var(f) ≈ ρ within 25% tolerance
    @testset "Variance calibration Var(μ)/Var(f) ≈ ρ" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        cal_rng = StableRNG(99)
        n = 10_000
        z = zeros(s)
        Ax = zeros(d)
        mu_vals = Vector{Float64}(undef, n)
        f_vals = Vector{Float64}(undef, n)
        for i in 1:n
            w = clamp.(randn(cal_rng, d), -3.0, 3.0)
            x = clamp.(randn(cal_rng, d), -3.0, 3.0)
            mu_vals[i] = eval_mu!(z, w, env)
            f_vals[i] = match_output_noiseless!(z, Ax, w, x, env)
        end
        var_mu = var(mu_vals)
        var_f = var(f_vals) + 1.0  # add noise variance σ²=1
        ratio = var_mu / var_f
        @test abs(ratio - rho) / rho < 0.25
    end

    # When ρ=0, μ contributes nothing
    @testset "rho=0 zeroes mu weights" begin
        env0 = generate_matching_function(d, s, 0.0, K_mu, StableRNG(42))
        @test all(env0.mu_weights .== 0.0)
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        z = zeros(s)
        @test eval_mu!(z, w, env0) == 0.0
    end

    # Noiseless output equals eval_mu + interaction exactly
    @testset "Decomposition: noiseless = μ + w⊤Ax" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        test_rng = StableRNG(77)
        z = zeros(s)
        Ax = zeros(d)
        @test all(1:20) do _
            w = clamp.(randn(test_rng, d), -3.0, 3.0)
            x = clamp.(randn(test_rng, d), -3.0, 3.0)
            mu_val = eval_mu!(z, w, env)
            mul!(Ax, env.A, x)
            match_output_noiseless!(z, Ax, w, x, env) ≈ mu_val + dot(w, Ax)
        end
    end

    # Nearby workers produce similar μ values (smoothness)
    @testset "eval_mu smoothness" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        perturbation = randn(StableRNG(2), d) .* 0.01
        w_near = clamp.(w .+ perturbation, -3.0, 3.0)
        z = zeros(s)
        @test abs(eval_mu!(z, w, env) - eval_mu!(z, w_near, env)) < 0.5
    end

    # calibrate_output_scale returns f_bar, f_mean, r_base with correct relationships
    @testset "calibrate_output_scale" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        curve = generate_firm_curve(d, StableRNG(10))
        ftypes = generate_firm_types(curve, 50, d, StableRNG(11))
        f_bar, f_mean, r_base = calibrate_output_scale(env, d, ftypes, StableRNG(55))
        @test f_bar > 0.0                # E[|f|] always positive
        @test r_base > 0.0
        @test r_base ≈ 0.70 * f_bar
        @test isfinite(f_mean)           # E[f] can be positive or negative
        @test f_bar >= abs(f_mean)       # E[|f|] >= |E[f]| by Jensen's inequality
    end

    # Same seed produces identical output
    @testset "Seed determinism" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        z = zeros(s)
        Ax = zeros(d)
        q1 = match_output!(z, Ax, w, x, env, StableRNG(10))
        q2 = match_output!(z, Ax, w, x, env, StableRNG(10))
        @test q1 == q2
    end

    # Independent MC check of f_bar using same firm types as calibration
    @testset "Statistical consistency of f_bar" begin
        env = generate_matching_function(d, s, rho, K_mu, StableRNG(42))
        curve2 = generate_firm_curve(d, StableRNG(10))
        ftypes2 = generate_firm_types(curve2, 50, d, StableRNG(11))
        f_bar, _, _ = calibrate_output_scale(env, d, ftypes2, StableRNG(55))
        check_rng = StableRNG(200)
        z = zeros(s)
        Ax = zeros(d)
        total = 0.0
        n_f = length(ftypes2)
        n = 10_000
        for _ in 1:n
            x = ftypes2[rand(check_rng, 1:n_f)]
            w = clamp.(x .+ randn(check_rng, d), -3.0, 3.0)
            total += abs(match_output_noiseless!(z, Ax, w, x, env))
        end
        f_bar_check = total / n
        @test abs(f_bar_check - f_bar) / f_bar < 0.10
    end

    # End-to-end: generate, evaluate, calibrate, all outputs finite
    @testset "Smoke test (Phase 1)" begin
        p = default_params()
        env = generate_matching_function(p.d, p.s, p.rho, p.K_mu, StableRNG(p.seed))
        w = clamp.(randn(StableRNG(1), p.d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(2), p.d), -3.0, 3.0)
        z = zeros(p.s)
        Ax = zeros(p.d)
        q = match_output!(z, Ax, w, x, env, StableRNG(3))
        @test isfinite(q)
        curve3 = generate_firm_curve(p.d, StableRNG(10))
        ftypes3 = generate_firm_types(curve3, 50, p.d, StableRNG(11))
        f_bar, f_mean, r_base = calibrate_output_scale(env, p.d, ftypes3, StableRNG(4))
        @test isfinite(f_bar)
        @test isfinite(f_mean)
        @test 0.0 < r_base < f_bar
    end
end
