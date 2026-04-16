using Test
using TransientBrokerage

@testset "Integration Tests" begin
    using DataFrames: nrow

    @testset "Full simulation completes without error" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42)
        state, df = run_simulation(p)
        @test nrow(df) == 20
        @test state.period == 20
    end

    @testset "Determinism: same seed produces identical results" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        _, df1 = run_simulation(p)
        _, df2 = run_simulation(p)
        @test df1.n_total_matches == df2.n_total_matches
        @test df1.outsourcing_rate == df2.outsourcing_rate
        @test df1.agent_holdout_r2 == df2.agent_holdout_r2
        @test df1.broker_holdout_r2 == df2.broker_holdout_r2
    end

    @testset "Different seeds produce different results" begin
        p1 = default_params(N=50, T=10, T_burn=2, seed=42)
        p2 = default_params(N=50, T=10, T_burn=2, seed=123)
        _, df1 = run_simulation(p1)
        _, df2 = run_simulation(p2)
        @test df1.n_total_matches != df2.n_total_matches
    end

    @testset "Match counts are consistent" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42)
        _, df = run_simulation(p)
        @test all(df.n_total_matches .== df.n_self_matches .+ df.n_broker_standard .+ df.n_broker_principal)
    end

    @testset "Outsourcing rate is bounded [0, 1]" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42)
        _, df = run_simulation(p)
        @test all(0.0 .<= df.outsourcing_rate .<= 1.0)
    end

    @testset "Roster fluctuates (agents leave when choosing self-search)" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42, eta=0.0)
        _, df = run_simulation(p)
        # Roster should not cover the entire population
        @test df.roster_size[end] < p.N
    end

    @testset "Principal mode simulation" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42, enable_principal=true)
        _, df = run_simulation(p)
        @test nrow(df) == 20
        @test all(0.0 .<= df.principal_mode_share .<= 1.0)
    end

    @testset "High-K regime" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, K=20)
        _, df = run_simulation(p)
        @test nrow(df) == 10
        @test df.n_total_matches[end] > 50
    end

    @testset "Lower-K regime" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, K=2)
        _, df = run_simulation(p)
        @test nrow(df) == 10
    end

    @testset "Holdout R² values are finite or NaN" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42)
        _, df = run_simulation(p)
        @test all(r2 -> isnan(r2) || isfinite(r2), df.agent_holdout_r2)
        @test all(r2 -> isnan(r2) || isfinite(r2), df.broker_holdout_r2)
    end

    @testset "Satisfaction values are finite" begin
        p = default_params(N=100, T=20, T_burn=5, seed=42)
        state, _ = run_simulation(p)
        @test all(isfinite(a.satisfaction_self) for a in state.agents)
        @test all(isfinite(a.satisfaction_broker) for a in state.agents)
    end

    @testset "Parameter regime variants complete without error" begin
        for (label, kwargs) in [
            ("delta=0", (delta=0.0,)),
            ("rho=0.1", (rho=0.1,)),
            ("rho=0.9", (rho=0.9,)),
        ]
            p = default_params(N=50, T=10, T_burn=2, seed=42; kwargs...)
            _, df = run_simulation(p)
            @test nrow(df) == 10
        end
    end
end
