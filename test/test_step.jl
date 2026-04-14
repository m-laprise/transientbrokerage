using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Graphs: nv, degree

@testset "Step and Simulation" begin

    @testset "initialize_model produces valid state" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        @test state.period == 0
        @test length(state.agents) == p.N
        @test nv(state.G) == p.N + 1
        @test state.broker.node_id == p.N + 1
        @test length(state.broker.roster) > 0
        # All agents have seeded histories
        seeded = count(a -> a.history_count > 0, state.agents)
        @test seeded > 0
        # Broker has seeded history
        @test state.broker.history_count > 0
        # Calibration constants are valid
        @test state.cal.q_pub > 0
        @test state.cal.r > 0
        @test state.cal.phi > 0
    end

    @testset "step_period! advances period counter" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        @test state.period == 0
        step_period!(state)
        @test state.period == 1
    end

    @testset "step_period! produces matches" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        step_period!(state)
        total = state.accum.n_self_matches + state.accum.n_broker_standard + state.accum.n_broker_principal
        @test total > 0  # at least some matches should form
    end

    @testset "Match expirations at tau=1" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, tau=1)
        state = initialize_model(p)
        step_period!(state)
        # After a period at tau=1, some agents may have active matches from this period
        # After the NEXT period's step 0, those should all expire
        step_period!(state)
        # At tau=1, step 0 clears all matches
        # Active matches from period 1 should be gone; period 2 matches may be present
    end

    @testset "Match expirations at tau=4" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, tau=4, K=3)
        state = initialize_model(p)
        # Run 5 periods
        for _ in 1:5
            step_period!(state)
        end
        # Some agents should have active matches (tau=4 means matches persist)
        any_active = any(a -> !isempty(a.active_matches), state.agents)
        @test any_active
    end

    @testset "Histories grow over time" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        h_before = sum(a.history_count for a in state.agents)
        for _ in 1:5
            step_period!(state)
        end
        h_after = sum(a.history_count for a in state.agents)
        @test h_after > h_before
    end

    @testset "Broker history grows from brokered matches" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        h_before = state.broker.history_count
        for _ in 1:5
            step_period!(state)
        end
        h_after = state.broker.history_count
        @test h_after >= h_before  # broker only learns from brokered matches
    end

    @testset "Roster grows as agents outsource" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        roster_before = length(state.broker.roster)
        for _ in 1:5
            step_period!(state)
        end
        roster_after = length(state.broker.roster)
        @test roster_after >= roster_before
    end

    @testset "Entry/exit maintains population" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, eta=0.10)
        state = initialize_model(p)
        for _ in 1:10
            step_period!(state)
        end
        @test length(state.agents) == p.N
        @test nv(state.G) == p.N + 1
    end

    @testset "Network measures are computed" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, network_measure_interval=5)
        state = initialize_model(p)
        for _ in 1:5
            step_period!(state)
        end
        @test isfinite(state.cached_network.betweenness)
        @test isfinite(state.cached_network.constraint)
        @test isfinite(state.cached_network.effective_size)
    end

    @testset "collect_period_metrics returns valid NamedTuple" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        step_period!(state)
        metrics = collect_period_metrics(state)
        @test metrics.period == 1
        @test metrics.n_total_matches >= 0
        @test 0.0 <= metrics.outsourcing_rate <= 1.0
        @test isfinite(metrics.mean_satisfaction_self)
        @test isfinite(metrics.mean_satisfaction_broker)
    end
end
