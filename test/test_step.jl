using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Graphs: nv, degree, has_edge

@testset "Step and Simulation" begin

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

    @testset "Roster size stays fixed at the target" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, eta=0.0)
        target = TransientBrokerage.roster_target_size(p.N)
        _, df = run_simulation(p)
        @test all(df.roster_size .== target)
    end

    @testset "Roster composition changes under churn" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, eta=0.0, roster_churn=0.5)
        state = initialize_model(p)
        roster_before = copy(state.broker.roster)
        for _ in 1:3
            step_period!(state)
        end
        @test state.broker.roster != roster_before
    end

    @testset "Current broker clients receive broker edges" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        client_id = first(i for i in 1:p.N if i ∉ state.broker.roster)

        push!(state.broker.current_clients, client_id)
        TransientBrokerage.sync_broker_edges!(state.G, state.agents, state.broker)

        @test has_edge(state.G, client_id, state.broker.node_id)
    end

    @testset "Broker access size uses the hybrid union without double counting" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42)
        state = initialize_model(p)
        roster_member = first(state.broker.roster)
        outside_member = first(i for i in 1:p.N if i ∉ state.broker.roster)

        push!(state.broker.current_clients, roster_member)
        push!(state.broker.current_clients, outside_member)

        @test TransientBrokerage.broker_access_size(state.broker) == length(state.broker.roster) + 1
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
        @test 0.0 <= metrics.outsourcing_rate_demanders <= 1.0
        @test 0 <= metrics.outsourced_slots <= metrics.total_demand
        @test isfinite(metrics.mean_satisfaction_self)
        @test isfinite(metrics.mean_satisfaction_broker)
        @test metrics.n_available == count(a -> available_capacity(a, p.K) > 0, state.agents)
        @test metrics.broker_access_size >= metrics.roster_size
        @test metrics.broker_access_size <= p.N
    end

    @testset "Holdout metrics are populated after stepping" begin
        p = default_params(N=80, T=10, T_burn=2, seed=42, eta=0.0)
        state = initialize_model(p)
        for _ in 1:3
            step_period!(state)
        end
        @test isfinite(state.accum.agent_holdout_rank)
        @test isfinite(state.accum.broker_holdout_rank)
        @test isfinite(state.accum.agent_holdout_rmse)
        @test isfinite(state.accum.broker_holdout_rmse)
    end
end
