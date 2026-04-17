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

    @testset "Round matching falls back within round after rejection" begin
        p_round = default_params(N=12, T=5, T_burn=1, K=1, n_strangers=0, seed=123)
        state_round = initialize_model(p_round)
        agents_r = state_round.agents
        G_r = state_round.G

        for agent_id in 1:4
            remove_agent_edges!(G_r, agent_id)
        end
        add_match_edge!(G_r, 1, 3)
        add_match_edge!(G_r, 1, 4)
        add_match_edge!(G_r, 2, 3)
        add_match_edge!(G_r, 2, 4)

        agents_r[1].partner_sum[3] = 10.0; agents_r[1].partner_count[3] = 1
        agents_r[1].partner_sum[4] = 5.0;  agents_r[1].partner_count[4] = 1
        agents_r[2].partner_sum[3] = 9.0;  agents_r[2].partner_count[3] = 1
        agents_r[2].partner_sum[4] = 4.0;  agents_r[2].partner_count[4] = 1

        agents_r[3].partner_sum[1] = 8.0; agents_r[3].partner_count[1] = 1
        agents_r[3].partner_sum[2] = 6.0; agents_r[3].partner_count[2] = 1
        agents_r[4].partner_sum[1] = 3.0; agents_r[4].partner_count[1] = 1
        agents_r[4].partner_sum[2] = 7.0; agents_r[4].partner_count[2] = 1

        accepted = TransientBrokerage.round_match_formation!(
            [1, 2], [:self, :self], [1, 1],
            agents_r, state_round.broker, state_round.env, G_r,
            p_round, state_round.cal, StableRNG(17)
        )

        accepted_pairs = Set((m.demander_id, m.counterparty_id) for m in accepted)
        @test length(accepted) == 2
        @test accepted_pairs == Set([(1, 3), (2, 4)])
    end

    @testset "Round matching fills one slot per round" begin
        p_round2 = default_params(N=12, T=5, T_burn=1, K=2, n_strangers=0, seed=321)
        state_round2 = initialize_model(p_round2)
        agents_r2 = state_round2.agents
        G_r2 = state_round2.G

        for agent_id in 1:3
            remove_agent_edges!(G_r2, agent_id)
        end
        add_match_edge!(G_r2, 1, 2)
        add_match_edge!(G_r2, 1, 3)

        agents_r2[1].partner_sum[2] = 9.0; agents_r2[1].partner_count[2] = 1
        agents_r2[1].partner_sum[3] = 8.0; agents_r2[1].partner_count[3] = 1
        agents_r2[2].partner_sum[1] = 7.0; agents_r2[2].partner_count[1] = 1
        agents_r2[3].partner_sum[1] = 6.0; agents_r2[3].partner_count[1] = 1

        accepted = TransientBrokerage.round_match_formation!(
            [1], [:self], [2],
            agents_r2, state_round2.broker, state_round2.env, G_r2,
            p_round2, state_round2.cal, StableRNG(23)
        )

        @test length(accepted) == 2
        @test Set(m.counterparty_id for m in accepted) == Set([2, 3])
        @test length(state_round2.agents[1].active_matches) == 2
    end

    @testset "Broker round cache matches direct round preferences" begin
        p_cache = default_params(N=18, T=5, T_burn=1, K=3, n_strangers=0, seed=404)
        state_cache = initialize_model(p_cache)
        ws_cache = state_cache.workspace
        agents_c = state_cache.agents

        empty!(state_cache.broker.roster)
        union!(state_cache.broker.roster, [5, 6, 7, 8])
        empty!(state_cache.broker.current_clients)
        union!(state_cache.broker.current_clients, [1, 3, 4])

        TransientBrokerage.reset_principal_inventory!(ws_cache, p_cache.N)
        TransientBrokerage.reserve_principal_capacity!(ws_cache, 7, 1)
        push!(agents_c[6].active_matches, ActiveMatch(9, false, :self))

        demand_agent_ids = [1, 2, 3, 4]
        demand_channels = [:broker, :self, :broker, :broker]
        broker_demanders = [1, 3, 4]
        demander_slots = [1, 0, 2]
        reserved_capacity = ws_cache.principal_reserved_capacity

        TransientBrokerage.prepare_period_broker_round_cache!(
            state_cache.broker, demand_agent_ids, demand_channels, agents_c, p_cache;
            ws=ws_cache, reserved_capacity=reserved_capacity
        )

        direct_out = ProposedMatch[]
        direct_counts = Int[]
        broker_matrix = TransientBrokerage.prepare_broker_round_matrix!(
            state_cache.broker, broker_demanders, agents_c, p_cache;
            reserved_capacity=reserved_capacity
        )
        TransientBrokerage.append_broker_round_preferences_from_matrix!(
            direct_out, direct_counts, broker_matrix, broker_demanders,
            agents_c, p_cache, state_cache.cal.r;
            demander_slots=demander_slots, reserved_capacity=reserved_capacity
        )

        cached_out = ProposedMatch[]
        cached_counts = Int[]
        TransientBrokerage.append_broker_round_preferences_from_cache!(
            cached_out, cached_counts, broker_demanders, agents_c,
            p_cache, state_cache.cal.r;
            ws=ws_cache, demander_slots=demander_slots,
            reserved_capacity=reserved_capacity
        )

        @test cached_counts == direct_counts
        @test cached_out == direct_out
    end

    @testset "Sequential formation accepts valid proposals" begin
        # Seed partner history so counterparties can evaluate
        for i in 1:10, j in 11:20
            update_partner_mean!(agents[j], i, 2.0)
            add_match_edge!(G, i, j)
        end
        proposals = [
            ProposedMatch(1, 15, :self, 2.0, false, NaN, NaN),
            ProposedMatch(2, 16, :broker, 2.0, false, NaN, NaN),
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
            push!(state2.agents[5].active_matches, ActiveMatch(10, false, :self))
        end
        proposals = [ProposedMatch(1, 5, :self, 10.0, false, NaN, NaN)]
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

        proposals = [ProposedMatch(1, 2, :self, 5.0, false, NaN, NaN)]
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

        proposals = [ProposedMatch(1, 2, :broker, 5.0, true, 1.0, 5.0)]
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
        phi = state5.cal.phi
        c_s = state5.cal.c_s

        # Agent 1 self-searches for two slots, gets one match. Self-search cost
        # is charged per demanded slot, regardless of fill.
        d_ids = [1]; d_chs = [:self]; d_cnts = [2]
        accepted = [(demander_id=1, counterparty_id=5, channel=:self,
                      is_principal=false, q_realized=2.0, q_predicted=1.5,
                      ask_j=NaN, capture_qhat=NaN)]
        sat_before = state5.agents[1].satisfaction_self
        update_satisfaction!(state5.agents, accepted, d_ids, d_chs, d_cnts, state5.cal, p)
        expected = (1 - omega) * sat_before + omega * (2.0 / 2 - c_s)
        @test state5.agents[1].satisfaction_self ≈ expected
    end

    @testset "Broker no-match decays satisfaction" begin
        state6 = initialize_model(p)
        omega = p.omega
        sat_before = state6.agents[1].satisfaction_broker
        d_ids = [1]; d_chs = [:broker]; d_cnts = [2]
        accepted = NamedTuple{(:demander_id, :counterparty_id, :channel, :is_principal,
                               :q_realized, :q_predicted, :ask_j, :capture_qhat),
                              Tuple{Int, Int, Symbol, Bool, Float64, Float64, Float64, Float64}}[]
        update_satisfaction!(state6.agents, accepted, d_ids, d_chs, d_cnts, state6.cal, p)
        @test state6.agents[1].satisfaction_broker ≈ (1 - omega) * sat_before
    end

    @testset "Self-search failure pays per-slot search cost" begin
        state6b = initialize_model(p)
        omega = p.omega
        sat_before = state6b.agents[1].satisfaction_self
        d_ids = [1]; d_chs = [:self]; d_cnts = [2]
        accepted = NamedTuple{(:demander_id, :counterparty_id, :channel, :is_principal,
                               :q_realized, :q_predicted, :ask_j, :capture_qhat),
                              Tuple{Int, Int, Symbol, Bool, Float64, Float64, Float64, Float64}}[]
        update_satisfaction!(state6b.agents, accepted, d_ids, d_chs, d_cnts, state6b.cal, p)
        expected = (1 - omega) * sat_before - omega * state6b.cal.c_s
        @test state6b.agents[1].satisfaction_self ≈ expected
    end

    @testset "Standard broker fee is charged only on successful placements" begin
        state6c = initialize_model(p)
        omega = p.omega
        sat_before = state6c.agents[1].satisfaction_broker
        d_ids = [1]; d_chs = [:broker]; d_cnts = [2]
        accepted = [(demander_id=1, counterparty_id=5, channel=:broker,
                      is_principal=false, q_realized=3.0, q_predicted=2.5,
                      ask_j=NaN, capture_qhat=NaN)]
        update_satisfaction!(state6c.agents, accepted, d_ids, d_chs, d_cnts, state6c.cal, p)
        expected = (1 - omega) * sat_before + omega * ((3.0 - state6c.cal.phi) / 2)
        @test state6c.agents[1].satisfaction_broker ≈ expected
    end

    @testset "Principal-mode satisfaction: no fee deducted" begin
        state7 = initialize_model(default_params(N=30, T=5, T_burn=1, K=3, seed=77, enable_principal=true))
        omega = p.omega
        sat_before = state7.agents[1].satisfaction_broker
        d_ids = [1]; d_chs = [:broker]; d_cnts = [2]
        accepted = [(demander_id=1, counterparty_id=5, channel=:broker,
                      is_principal=true, q_realized=3.0, q_predicted=2.5,
                      ask_j=1.0, capture_qhat=2.5)]
        update_satisfaction!(state7.agents, accepted, d_ids, d_chs, d_cnts, state7.cal, state7.params)
        # No fee for principal mode: cost = 0
        expected = (1 - omega) * sat_before + omega * (3.0 / 2)
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

        # Reverse: broker satisfaction much higher than self
        agent.satisfaction_self = 1.0
        agent.satisfaction_broker = 50.0
        @test outsourcing_decision(agent, state8.agents, G8, bn8, 0.0, 1, state8.cal.c_s, K8, StableRNG(1)) == :broker
    end

    @testset "Outsourcing ignores known-partner means as a separate hurdle" begin
        state8b = initialize_model(p)
        G8b = state8b.G; bn8b = state8b.broker.node_id; K8b = p.K
        agent = state8b.agents[1]
        nbr = first(filter(n -> n != bn8b, neighbors(G8b, agent.id)))

        agent.satisfaction_self = 1.0
        agent.satisfaction_broker = 10.0
        agent.tried_broker = true
        agent.partner_sum[nbr] = 100.0
        agent.partner_count[nbr] = 1

        @test outsourcing_decision(agent, state8b.agents, G8b, bn8b, 0.0, 1, state8b.cal.c_s, K8b, StableRNG(1)) == :broker
    end

    @testset "Untried broker uses reputation" begin
        state9 = initialize_model(p)
        G9 = state9.G; bn9 = state9.broker.node_id; K9 = p.K
        agent = state9.agents[1]
        agent.tried_broker = false
        agent.satisfaction_self = 0.0
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
