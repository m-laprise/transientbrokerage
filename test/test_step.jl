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
        @test state.cal.q_cal > 0
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

    @testset "Agent retraining schedule alternates by parity" begin
        @test TransientBrokerage.agent_retrains_this_period(1, 1)
        @test !TransientBrokerage.agent_retrains_this_period(2, 1)
        @test !TransientBrokerage.agent_retrains_this_period(1, 2)
        @test TransientBrokerage.agent_retrains_this_period(2, 2)
    end

    @testset "step_period! produces matches" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        step_period!(state)
        total = state.accum.n_self_matches + state.accum.n_broker_standard + state.accum.n_broker_principal
        @test total > 0  # at least some matches should form
    end

    @testset "Current-period match ledger resets before demand generation" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        push!(state.agents[1].active_matches, ActiveMatch(0, false, :self))
        step_period!(state)
        @test all(am.partner_id != 0 for a in state.agents for am in a.active_matches)
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

    @testset "Roster is dynamic (agents join and leave)" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        for _ in 1:5; step_period!(state); end
        # Roster should be less than N (not everyone outsources)
        @test length(state.broker.roster) < p.N
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
