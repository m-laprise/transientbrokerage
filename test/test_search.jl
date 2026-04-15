using Test
using TransientBrokerage
using StableRNGs: StableRNG

@testset "Search" begin
    p = default_params(N=30, T=5, T_burn=1, K=3, seed=42)
    state = initialize_model(p)
    agents = state.agents
    broker = state.broker
    G = state.G
    cal = state.cal

    @testset "Self-search returns valid proposals" begin
        rng = StableRNG(99)
        props = self_search(agents[1], agents, G, broker.node_id, p, rng, 2, cal.r)
        for pm in props
            @test pm.demander_id == 1
            @test pm.counterparty_id != 1
            @test 1 <= pm.counterparty_id <= p.N
            @test pm.channel == :self
            @test pm.is_principal == false
            @test isfinite(pm.evaluation)
        end
    end

    @testset "Self-search uses history for known neighbors" begin
        p2 = default_params(N=20, T=5, T_burn=1, K=3, n_strangers=0, seed=7)
        state2 = initialize_model(p2)
        agents2 = state2.agents
        G2 = state2.G
        broker_node2 = state2.broker.node_id

        remove_agent_edges!(G2, 1)
        add_match_edge!(G2, 1, 2)
        agents2[1].partner_sum[2] = 100.0
        agents2[1].partner_count[2] = 1

        rng = StableRNG(77)
        props = self_search(agents2[1], agents2, G2, broker_node2, p2, rng, 1, -1e9)

        @test length(props) == 1
        @test props[1].counterparty_id == 2
        @test props[1].evaluation ≈ 100.0
    end

    @testset "Self-search respects participation constraint" begin
        rng = StableRNG(55)
        props = self_search(agents[1], agents, G, broker.node_id, p, rng, 1, 1e6)
        @test isempty(props)
    end

    @testset "Broker allocation produces valid proposals" begin
        client_demands = [(1, 2), (5, 1)]
        rng = StableRNG(88)
        props = broker_allocate(broker, client_demands, agents, p, rng, cal.r)
        for pm in props
            @test pm.demander_id in [1, 5]
            @test pm.counterparty_id != pm.demander_id
            @test pm.channel == :broker
        end
    end

    @testset "Broker allocation excludes self-matches" begin
        push!(broker.roster, 1)
        client_demands = [(1, 1)]
        rng = StableRNG(66)
        props = broker_allocate(broker, client_demands, agents, p, rng, 0.0)
        @test all(pm -> pm.demander_id != pm.counterparty_id, props)
    end

    @testset "Broker allocation respects capacity" begin
        for _ in 1:p.K
            push!(agents[2].active_matches, ActiveMatch(3, 0, false, :self))
        end
        push!(broker.roster, 2)
        client_demands = [(1, 1)]
        rng = StableRNG(44)
        props = broker_allocate(broker, client_demands, agents, p, rng, 0.0)
        @test all(pm -> pm.counterparty_id != 2, props)
        empty!(agents[2].active_matches)
    end
end
