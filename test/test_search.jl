using Test
using TransientBrokerage
using StableRNGs: StableRNG

@testset "Search" begin
    @testset "Self-round preferences use known-neighbor history and rank by value" begin
        p = default_params(N=20, T=5, T_burn=1, K=3, n_strangers=0, seed=7)
        state = initialize_model(p)
        agents = state.agents
        G = state.G

        remove_agent_edges!(G, 1)
        add_match_edge!(G, 1, 2)
        add_match_edge!(G, 1, 3)
        agents[1].partner_sum[2] = 9.0; agents[1].partner_count[2] = 1
        agents[1].partner_sum[3] = 7.0; agents[1].partner_count[3] = 1

        out = ProposedMatch[]
        n_added = TransientBrokerage.append_self_round_preferences!(
            out, agents[1], agents, G, state.broker.node_id, p, StableRNG(77), -1e9;
            ws=state.workspace
        )

        @test n_added == 2
        @test [pm.counterparty_id for pm in out] == [2, 3]
        @test [pm.evaluation for pm in out] == [9.0, 7.0]
    end

    @testset "Self-round preferences respect participation and counterparty capacity" begin
        p = default_params(N=20, T=5, T_burn=1, K=3, n_strangers=0, seed=11)
        state = initialize_model(p)
        agents = state.agents
        G = state.G

        remove_agent_edges!(G, 1)
        add_match_edge!(G, 1, 2)
        agents[1].partner_sum[2] = 100.0
        agents[1].partner_count[2] = 1
        for _ in 1:p.K
            push!(agents[2].active_matches, ActiveMatch(9, false, :self))
        end

        out = ProposedMatch[]
        n_added = TransientBrokerage.append_self_round_preferences!(
            out, agents[1], agents, G, state.broker.node_id, p, StableRNG(71), -1e9;
            ws=state.workspace
        )
        @test n_added == 0
        @test isempty(out)

        n_added = TransientBrokerage.append_self_round_preferences!(
            out, agents[1], agents, G, state.broker.node_id, p, StableRNG(71), 1e6;
            ws=state.workspace
        )
        @test n_added == 0
        @test isempty(out)
    end

    @testset "Broker cache uses hybrid access set and excludes self matches" begin
        p = default_params(N=20, T=5, T_burn=1, K=2, seed=17)
        state = initialize_model(p)
        broker = state.broker
        agents = state.agents
        ws = state.workspace

        empty!(broker.roster)
        empty!(broker.current_clients)
        union!(broker.roster, [1, 2])
        push!(broker.current_clients, 3)

        demand_agent_ids = [1]
        demand_channels = [:broker]
        demander_slots = [1]

        TransientBrokerage.prepare_period_broker_round_cache!(
            broker, demand_agent_ids, demand_channels, agents, p;
            ws=ws
        )

        out = ProposedMatch[]
        counts = Int[]
        TransientBrokerage.append_broker_round_preferences_from_cache!(
            out, counts, demand_agent_ids, agents, p, -1e9;
            ws=ws, demander_slots=demander_slots
        )

        @test counts == [2]
        @test Set(pm.counterparty_id for pm in out) == Set([2, 3])
        @test all(pm -> pm.demander_id == 1, out)
        @test all(pm -> pm.counterparty_id != pm.demander_id, out)
    end

    @testset "Broker cache respects live capacity" begin
        p = default_params(N=20, T=5, T_burn=1, K=2, seed=19)
        state = initialize_model(p)
        broker = state.broker
        agents = state.agents
        ws = state.workspace

        empty!(broker.roster)
        empty!(broker.current_clients)
        push!(broker.current_clients, 2)
        for _ in 1:p.K
            push!(agents[2].active_matches, ActiveMatch(3, false, :self))
        end

        TransientBrokerage.prepare_period_broker_round_cache!(
            broker, [1], [:broker], agents, p;
            ws=ws
        )

        out = ProposedMatch[]
        counts = Int[]
        TransientBrokerage.append_broker_round_preferences_from_cache!(
            out, counts, [1], agents, p, -1e9;
            ws=ws, demander_slots=[1]
        )

        @test counts == [0]
        @test isempty(out)
    end

    @testset "Broker cache append is allocation-free after warmup" begin
        p = default_params(N=60, T=5, T_burn=1, K=3, n_strangers=0, seed=23)
        state = initialize_model(p)
        ws = state.workspace
        broker = state.broker
        agents = state.agents
        demand_agent_ids = collect(1:15)
        demand_channels = fill(:broker, length(demand_agent_ids))
        demander_slots = fill(1, length(demand_agent_ids))
        out = ProposedMatch[]
        counts = Int[]

        TransientBrokerage.prepare_period_broker_round_cache!(
            broker, demand_agent_ids, demand_channels, agents, p;
            ws=ws
        )
        TransientBrokerage.append_broker_round_preferences_from_cache!(
            out, counts, demand_agent_ids, agents, p, state.cal.r;
            ws=ws, demander_slots=demander_slots
        )
        empty!(out)
        empty!(counts)

        alloc = @allocated TransientBrokerage.append_broker_round_preferences_from_cache!(
            out, counts, demand_agent_ids, agents, p, state.cal.r;
            ws=ws, demander_slots=demander_slots
        )
        @test alloc <= 256
    end
end
