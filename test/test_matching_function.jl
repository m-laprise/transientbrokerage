using Test
using TransientBrokerage
using StableRNGs: StableRNG
using LinearAlgebra: dot, norm, normalize, eigvals

@testset "Matching Function" begin
    d = 8
    rho = 0.50

    function test_agent_types(d, n, rng)
        [normalize(randn(rng, d)) for _ in 1:n]
    end

    @testset "MatchingEnv construction" begin
        types = test_agent_types(d, 50, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        @test env.d == d
        @test env.rho == rho
        @test env.delta == 0.5
        @test length(env.c) == d
        @test size(env.A) == (d, d)
        @test size(env.B) == (d, d)
    end

    @testset "A and B are SPD" begin
        types = test_agent_types(d, 50, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        @test all(eigvals(env.A) .> 0)
        @test all(eigvals(env.B) .> 0)
        @test env.A ≈ env.A'
        @test env.B ≈ env.B'
    end

    @testset "Matching function symmetry: f(x_i, x_j) == f(x_j, x_i)" begin
        types = test_agent_types(d, 20, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        rng = StableRNG(99)
        @test all(1:100) do _
            i, j = rand(rng, 1:20), rand(rng, 1:20)
            match_signal(types[i], types[j], env) ≈ match_signal(types[j], types[i], env)
        end
    end

    @testset "Regime gain values" begin
        types = test_agent_types(d, 20, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        rng = StableRNG(77)
        gains = [regime_gain(types[rand(rng, 1:20)], types[rand(rng, 1:20)], env) for _ in 1:100]
        # All gains should be 1+delta or 1-delta
        @test all(g -> g ≈ 0.5 || g ≈ 1.5, gains)
    end

    @testset "Regime gain symmetry: g(x_i, x_j) == g(x_j, x_i)" begin
        types = test_agent_types(d, 20, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        rng = StableRNG(55)
        @test all(1:50) do _
            i, j = rand(rng, 1:20), rand(rng, 1:20)
            regime_gain(types[i], types[j], env) ≈ regime_gain(types[j], types[i], env)
        end
    end

    @testset "At delta=0, gain is always 1.0" begin
        types = test_agent_types(d, 20, StableRNG(10))
        env0 = generate_matching_env(d, rho, 0.0, 0.25, types, StableRNG(42))
        rng = StableRNG(77)
        @test all(1:50) do _
            i, j = rand(rng, 1:20), rand(rng, 1:20)
            regime_gain(types[i], types[j], env0) ≈ 1.0
        end
    end

    @testset "Mixing weight rho" begin
        types = test_agent_types(d, 20, StableRNG(10))
        # At rho=1: pure quality, no interaction
        env1 = generate_matching_env(d, 1.0, 0.5, 0.25, types, StableRNG(42))
        xi, xj = types[1], types[2]
        expected_q = 0.5 * (dot(xi, env1.c) + dot(xj, env1.c))
        @test match_signal(xi, xj, env1) ≈ expected_q

        # At rho=0: pure interaction, no quality
        env0 = generate_matching_env(d, 0.0, 0.5, 0.25, types, StableRNG(42))
        g = regime_gain(xi, xj, env0)
        expected_int = g * dot(xi, env0.A * xj)
        @test match_signal(xi, xj, env0) ≈ expected_int
    end

    @testset "In-place match_signal! matches allocating version" begin
        types = test_agent_types(d, 20, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        Ax = zeros(d)
        Bx = zeros(d)
        rng = StableRNG(33)
        @test all(1:20) do _
            i, j = rand(rng, 1:20), rand(rng, 1:20)
            match_signal(types[i], types[j], env) ≈
                match_signal!(Ax, Bx, types[i], types[j], env)
        end
    end

    @testset "match_output includes Q_OFFSET and noise" begin
        types = test_agent_types(d, 20, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        xi, xj = types[1], types[2]
        rng1 = StableRNG(99)
        q1 = match_output(xi, xj, env, rng1)
        rng2 = StableRNG(99)
        q2 = Q_OFFSET + match_signal(xi, xj, env) + env.sigma_eps * randn(rng2)
        @test q1 ≈ q2
    end

    @testset "Calibration produces valid constants" begin
        types = test_agent_types(d, 100, StableRNG(10))
        env = generate_matching_env(d, rho, 0.5, 0.25, types, StableRNG(42))
        p = default_params()
        cal = calibrate(env, types, p, StableRNG(55))
        @test cal.q_pub > 0.0
        @test cal.r > 0.0
        @test cal.r ≈ R_BASE_FRAC * cal.q_pub
        @test cal.phi > 0.0
        @test cal.c_s ≈ p.gamma_c * cal.phi
        @test cal.c_s < cal.phi  # self-search cheaper than broker fee
    end

    @testset "Two regimes produce different match qualities" begin
        types = test_agent_types(d, 50, StableRNG(10))
        env = generate_matching_env(d, 0.0, 0.5, 0.0, types, StableRNG(42))  # pure interaction, no noise
        # Find pairs in each regime
        high_gain = Float64[]
        low_gain = Float64[]
        for i in 1:50, j in (i+1):50
            g = regime_gain(types[i], types[j], env)
            q = match_signal(types[i], types[j], env)
            if g > 1.0
                push!(high_gain, q)
            else
                push!(low_gain, q)
            end
        end
        # Both regimes should be populated
        @test length(high_gain) > 10
        @test length(low_gain) > 10
    end
end
