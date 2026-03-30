using Test
using TransientBrokerage
using StableRNGs: StableRNG
using LinearAlgebra: dot, norm
using Statistics: var

@testset "Phase 1: Matching Function" begin
    d, rho = 8, 0.50

    function test_firm_types(d, rng)
        curve = generate_firm_curve(d, rng)
        generate_firm_types(curve, 50, d, rng)
    end

    # generate_matching_function returns a valid MatchingEnv
    @testset "Construction and dimensions" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        @test env.d == d
        @test env.rho == rho
        @test length(env.c) == d
        @test env.c_norm ≈ norm(env.c)
    end

    # Components are cosine-normalized (bounded)
    @testset "Component bounds" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        rng = StableRNG(99)
        mus = [eval_mu(clamp.(randn(rng, d), -3.0, 3.0), env) for _ in 1:100]
        ints = [eval_interaction(clamp.(randn(rng, d), -3.0, 3.0),
                                 clamp.(randn(rng, d), -3.0, 3.0)) for _ in 1:100]
        @test all(-1.0 .<= mus .<= 1.0)       # tanh(cos) ∈ [-1,1]
        @test all(-1.0 .<= ints .<= 1.0)      # cosine sim
    end

    # Mixing: at rho=0, output is pure interaction; at rho=1, pure quality
    @testset "Mixing weight rho" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env0 = generate_matching_function(d, 0.0, ftypes, StableRNG(42))
        env1 = generate_matching_function(d, 1.0, ftypes, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(2), d), -3.0, 3.0)
        @test match_output_noiseless(w, x, env0) ≈ TransientBrokerage.Q_OFFSET + eval_interaction(w, x)
        @test match_output_noiseless(w, x, env1) ≈ TransientBrokerage.Q_OFFSET + eval_mu(w, env1)
    end

    # Noiseless output equals rho*mu + (1-rho)*interaction exactly
    @testset "Decomposition: noiseless = rho*mu + (1-rho)*interaction" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        test_rng = StableRNG(77)
        @test all(1:20) do _
            w = clamp.(randn(test_rng, d), -3.0, 3.0)
            x = clamp.(randn(test_rng, d), -3.0, 3.0)
            expected = TransientBrokerage.Q_OFFSET + rho * eval_mu(w, env) + (1.0 - rho) * eval_interaction(w, x)
            match_output_noiseless(w, x, env) ≈ expected
        end
    end

    # Nearby workers produce similar mu values (smoothness)
    @testset "eval_mu smoothness" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        w_near = clamp.(w .+ randn(StableRNG(2), d) .* 0.01, -3.0, 3.0)
        @test abs(eval_mu(w, env) - eval_mu(w_near, env)) < 0.1
    end

    # calibrate_output_scale returns f_mean and r_base with correct relationship
    @testset "calibrate_output_scale" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        f_mean, r_base = calibrate_output_scale(env, ftypes, StableRNG(55))
        @test f_mean > 0.0
        @test r_base > 0.0
        @test r_base ≈ 0.70 * f_mean
    end

    # Same seed produces identical output
    @testset "Seed determinism" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        w = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(1), d), -3.0, 3.0)
        q1 = match_output(w, x, env, StableRNG(10))
        q2 = match_output(w, x, env, StableRNG(10))
        @test q1 == q2
    end

    # Independent MC check of f_mean (random worker-firm pairs, matching calibration)
    @testset "Statistical consistency of f_mean" begin
        ftypes = test_firm_types(d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        sigma_w = 0.5
        f_mean, _ = calibrate_output_scale(env, ftypes, StableRNG(55); sigma_w=sigma_w)
        σ_per_dim = sigma_w / sqrt(d)
        check_rng = StableRNG(200)
        n_f = length(ftypes)
        total = sum(1:10_000) do _
            ref = ftypes[rand(check_rng, 1:n_f)]
            w = clamp.(ref .+ σ_per_dim .* randn(check_rng, d), -3.0, 3.0)
            x = ftypes[rand(check_rng, 1:n_f)]  # independent firm
            match_output_noiseless(w, x, env)
        end
        f_mean_check = total / 10_000
        @test abs(f_mean_check - f_mean) / max(abs(f_mean), 0.01) < 0.10
    end

    # End-to-end smoke test
    @testset "Smoke test (Phase 1)" begin
        p = default_params()
        ftypes = test_firm_types(p.d, StableRNG(10))
        env = generate_matching_function(p.d, p.rho, ftypes, StableRNG(p.seed))
        w = clamp.(randn(StableRNG(1), p.d), -3.0, 3.0)
        x = clamp.(randn(StableRNG(2), p.d), -3.0, 3.0)
        q = match_output(w, x, env, StableRNG(3))
        @test isfinite(q)
        f_mean, r_base = calibrate_output_scale(env, ftypes, StableRNG(4))
        @test isfinite(f_mean)
    end
end
