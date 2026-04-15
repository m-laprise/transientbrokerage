using Test
using TransientBrokerage
using Graphs: has_edge, neighbors
using StableRNGs: StableRNG

@testset "Match Formation and Outsourcing" begin
    p = default_params(N=30, T=5, T_burn=1, K=3, seed=42)
    state = initialize_model(p)
    agents = state.agents
    broker = state.broker
    G = state.G
    cal = state.cal
    env = state.env

    @testset "Sequential formation accepts valid proposals" begin
        # Seed partner history so counterparties can evaluate
        for i in 1:10, j in 11:20
            update_partner_mean!(agents[j], i, 2.0)
            add_match_edge!(G, i, j)
        end
        proposals = [
            ProposedMatch(1, 15, :self, 2.0, false, NaN),
            ProposedMatch(2, 16, :broker, 2.0, false, NaN),
        ]
        rng = StableRNG(77)
        accepted = sequential_match_formation!(proposals, agents, broker, env, G, p, cal, rng)
        @test length(accepted) >= 1
        for m in accepted
            @test isfinite(m.q_realized)
            @test 1 <= m.demander_id <= p.N
            @test 1 <= m.counterparty_id <= p.N
        end
    end

    @testset "Sequential formation checks capacity" begin
        state2 = initialize_model(p)
        # Fill agent 5's capacity
        for _ in 1:p.K
            push!(state2.agents[5].active_matches, ActiveMatch(10, 0, false, :self))
        end
        proposals = [ProposedMatch(1, 5, :self, 10.0, false, NaN)]
        for j in 1:30
            update_partner_mean!(state2.agents[5], 1, 2.0)
            update_partner_mean!(state2.agents[1], 5, 2.0)
        end
        add_match_edge!(state2.G, 1, 5)
        rng = StableRNG(88)
        accepted = sequential_match_formation!(proposals, state2.agents, state2.broker,
                                                state2.env, state2.G, p, cal, rng)
        # Agent 5 has no capacity, should be skipped
        @test isempty(accepted)
    end

    @testset "Standard match creates edge and updates histories" begin
        state3 = initialize_model(p)
        a1, a2 = state3.agents[1], state3.agents[2]
        h1_before = a1.history_count
        h2_before = a2.history_count

        # Seed partner history so counterparty evaluates positively
        update_partner_mean!(a2, 1, 5.0)
        add_match_edge!(state3.G, 1, 2)

        proposals = [ProposedMatch(1, 2, :self, 5.0, false, NaN)]
        rng = StableRNG(55)
        accepted = sequential_match_formation!(proposals, state3.agents, state3.broker,
                                                state3.env, state3.G, p, cal, rng)
        @test length(accepted) == 1
        @test a1.history_count == h1_before + 1
        @test a2.history_count == h2_before + 1
        @test has_edge(state3.G, 1, 2)
    end

    @testset "Principal match does NOT update agent histories or create edges" begin
        state4 = initialize_model(default_params(N=30, T=5, T_burn=1, K=3, seed=99, enable_principal=true))
        a1, a2 = state4.agents[1], state4.agents[2]
        h1_before = a1.history_count
        h2_before = a2.history_count
        broker_h_before = state4.broker.history_count

        # Remove edge if exists so we can check it's not added
        TransientBrokerage.remove_agent_edges!(state4.G, 1)

        proposals = [ProposedMatch(1, 2, :broker, 5.0, true, 1.0)]
        rng = StableRNG(44)
        accepted = sequential_match_formation!(proposals, state4.agents, state4.broker,
                                                state4.env, state4.G,
                                                state4.params, state4.cal, rng)
        @test length(accepted) == 1
        @test a1.history_count == h1_before       # NOT updated
        @test a2.history_count == h2_before       # NOT updated
        @test state4.broker.history_count == broker_h_before + 1  # broker learns
        @test !has_edge(state4.G, 1, 2)           # no edge formed
    end

    @testset "Satisfaction EWMA update" begin
        state5 = initialize_model(p)
        omega = p.omega
        q_cal = state5.cal.q_cal
        phi = state5.cal.phi
        c_s = state5.cal.c_s

        # Agent 1 self-searches, gets one match
        d_ids = [1]; d_chs = [:self]; d_cnts = [1]
        accepted = [(demander_id=1, counterparty_id=5, channel=:self,
                      is_principal=false, q_realized=2.0, q_predicted=1.5)]
        sat_before = state5.agents[1].satisfaction_self
        update_satisfaction!(state5.agents, accepted, d_ids, d_chs, state5.cal, p)
        expected = (1 - omega) * sat_before + omega * (2.0 - c_s)
        @test state5.agents[1].satisfaction_self ≈ expected
    end

    @testset "No-match penalty decays satisfaction" begin
        state6 = initialize_model(p)
        omega = p.omega
        sat_before = state6.agents[1].satisfaction_broker
        d_ids = [1]; d_chs = [:broker]
        accepted = NamedTuple{(:demander_id, :counterparty_id, :channel, :is_principal, :q_realized, :q_predicted),
                              Tuple{Int, Int, Symbol, Bool, Float64, Float64}}[]
        update_satisfaction!(state6.agents, accepted, d_ids, d_chs, state6.cal, p)
        @test state6.agents[1].satisfaction_broker ≈ (1 - omega) * sat_before
    end

    @testset "Principal-mode satisfaction: no fee deducted" begin
        state7 = initialize_model(default_params(N=30, T=5, T_burn=1, K=3, seed=77, enable_principal=true))
        omega = p.omega
        sat_before = state7.agents[1].satisfaction_broker
        d_ids = [1]; d_chs = [:broker]
        accepted = [(demander_id=1, counterparty_id=5, channel=:broker,
                      is_principal=true, q_realized=3.0, q_predicted=2.5)]
        update_satisfaction!(state7.agents, accepted, d_ids, d_chs, state7.cal, state7.params)
        # No fee for principal mode: cost = 0
        expected = (1 - omega) * sat_before + omega * 3.0
        @test state7.agents[1].satisfaction_broker ≈ expected
    end

    @testset "Outsourcing decision follows satisfaction" begin
        state8 = initialize_model(p)
        G8 = state8.G; bn8 = state8.broker.node_id; K8 = p.K
        agent = state8.agents[1]
        # High self-satisfaction, low broker satisfaction
        agent.satisfaction_self = 5.0
        agent.satisfaction_broker = 1.0
        agent.tried_broker = true
        @test outsourcing_decision(agent, state8.agents, G8, bn8, 0.0, 1, state8.cal.c_s, K8, StableRNG(1)) == :self

        # Reverse: broker satisfaction much higher than self AND known partners
        agent.satisfaction_self = 1.0
        agent.satisfaction_broker = 50.0  # much higher than any known partner
        @test outsourcing_decision(agent, state8.agents, G8, bn8, 0.0, 1, state8.cal.c_s, K8, StableRNG(1)) == :broker
    end

    @testset "Untried broker uses reputation" begin
        state9 = initialize_model(p)
        G9 = state9.G; bn9 = state9.broker.node_id; K9 = p.K
        agent = state9.agents[1]
        agent.tried_broker = false
        agent.satisfaction_self = 0.0
        # Clear all partner means so score_known = -Inf
        fill!(agent.partner_count, 0)
        # High broker reputation should make agent outsource
        @test outsourcing_decision(agent, state9.agents, G9, bn9, 10.0, 1, state9.cal.c_s, K9, StableRNG(1)) == :broker
    end

    @testset "Broker reputation update" begin
        state10 = initialize_model(p)
        state10.agents[1].satisfaction_broker = 3.0
        state10.agents[2].satisfaction_broker = 5.0
        client_ids = [1, 2]
        update_broker_reputation!(state10.broker, state10.agents, client_ids)
        @test state10.broker.last_reputation ≈ 4.0
        @test state10.broker.has_had_clients == true
    end

    @testset "Broker reputation is sticky with no clients" begin
        state11 = initialize_model(p)
        state11.broker.last_reputation = 3.5
        state11.broker.has_had_clients = true
        update_broker_reputation!(state11.broker, state11.agents, Int[])
        @test state11.broker.last_reputation == 3.5  # unchanged
    end
end
