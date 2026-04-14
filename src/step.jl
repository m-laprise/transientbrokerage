"""
    step.jl

Main simulation loop: one period of the model (§9, Steps 0-6).

Step 0: Match expirations
Step 1: Demand generation and outsourcing decisions
Step 2: Candidate evaluation (train NNs, self-search, broker allocation, mode selection)
Step 3: Match formation (sequential acceptance)
Step 4: Learning updates (histories already recorded in Step 3; satisfaction, reputation)
Step 5: Entry/exit
Step 6: Recording and measurement
"""

using Random: AbstractRNG
using Distributions: Binomial
using Graphs: neighbors, has_edge
using LinearAlgebra: BLAS
using Base.Threads: @threads

# ─────────────────────────────────────────────────────────────────────────────

"""
    step_period!(state) -> Nothing

Execute one complete period of the simulation.
"""
function step_period!(state::ModelState)
    state.period += 1
    p = state.params
    rng = state.rng
    N = p.N
    K = p.K
    d = p.d
    agents = state.agents
    broker = state.broker
    G = state.G
    env = state.env
    cal = state.cal

    reset_accumulators!(state.accum)

    # ══════════════════════════════════════════════════════════════════════
    # Step 0: Match expirations
    # ══════════════════════════════════════════════════════════════════════
    if p.tau > 1
        current = state.period
        for agent in agents
            filter!(m -> (current - m.formation_period) < p.tau, agent.active_matches)
        end
    else
        # tau=1: all matches dissolve immediately
        for agent in agents
            empty!(agent.active_matches)
        end
    end

    # ══════════════════════════════════════════════════════════════════════
    # Step 1: Demand generation and outsourcing decisions
    # ══════════════════════════════════════════════════════════════════════
    ws = state.workspace

    # Reuse workspace vectors (avoid Dict/Set allocation every period)
    demand_agent_ids = ws.demand_agent_ids; empty!(demand_agent_ids)
    demand_channels = ws.demand_channels; empty!(demand_channels)
    demand_counts = ws.demand_counts; empty!(demand_counts)
    client_demands = ws.client_demands_ws; empty!(client_demands)
    broker_clients = ws.broker_clients_ws; empty!(broker_clients)

    broker_rep = broker_reputation(broker, cal.q_pub)

    for i in 1:N
        agents[i].periods_alive += 1
        avail_cap = available_capacity(agents[i], K)
        avail_cap <= 0 && continue

        d_i = rand(rng, Binomial(avail_cap, p.p_demand))
        d_i <= 0 && continue

        channel = outsourcing_decision(agents[i], broker_rep, rng)

        push!(demand_agent_ids, i)
        push!(demand_channels, channel)
        push!(demand_counts, d_i)
        state.accum.n_demanders += 1

        if channel == :broker
            push!(client_demands, (i, d_i))
            push!(broker_clients, i)
            state.accum.n_outsourced += 1
            if !agents[i].on_roster
                agents[i].on_roster = true
                push!(broker.roster, i)
                add_broker_edge!(G, i, broker.node_id)
            end
        end
    end

    # ══════════════════════════════════════════════════════════════════════
    # Step 2: Candidate evaluation
    # ══════════════════════════════════════════════════════════════════════

    # 2.1: Train neural networks (adaptive steps).
    # Agent NNs are independent; train_nn! materializes contiguous Matrix/Vector
    # copies so train_step! sees concrete types (no SubArray BLAS overhead).
    prev_blas = BLAS.get_num_threads()
    BLAS.set_num_threads(1)
    @threads for i in 1:N
        a = agents[i]
        a.history_count > 0 && a.n_new_obs > 0 && train_agent_nn!(a, p)
    end
    BLAS.set_num_threads(prev_blas)
    if broker.history_count > 0 && broker.n_new_obs > 0
        train_broker_nn!(broker, p)
    end

    # 2.2: Self-searches (workspace reused across agents, appending into all_proposals)
    all_proposals = ProposedMatch[]
    for idx in eachindex(demand_agent_ids)
        if demand_channels[idx] == :self
            self_search(agents[demand_agent_ids[idx]], agents, G, broker.node_id, p, rng,
                        demand_counts[idx], cal.r; ws=ws, proposals=all_proposals)
        end
    end

    # 2.3: Broker allocation (appends into all_proposals using same workspace)
    broker_allocate(broker, client_demands, agents, p, rng, cal.r;
                    ws=ws, proposals=all_proposals)

    # 2.4: Mode selection (principal vs standard for broker matches)
    if p.enable_principal
        apply_mode_selection!(all_proposals, agents, p, cal)
    end

    # Snapshot pre-formation edge state for access/assessment classification.
    # Must check BEFORE formation adds new edges. Use parallel vectors (no Set alloc).
    wc_i = ws.was_connected_i; empty!(wc_i)
    wc_j = ws.was_connected_j; empty!(wc_j)
    for pm in all_proposals
        if pm.channel == :broker && has_edge(G, pm.demander_id, pm.counterparty_id)
            push!(wc_i, pm.demander_id)
            push!(wc_j, pm.counterparty_id)
        end
    end

    # ══════════════════════════════════════════════════════════════════════
    # Step 3: Match formation (sequential acceptance)
    # ══════════════════════════════════════════════════════════════════════
    accepted = sequential_match_formation!(all_proposals, agents, broker, env, G, p, cal, rng)

    # Set formation period on active matches (was set to 0 during formation)
    for agent in agents
        for idx in eachindex(agent.active_matches)
            am = agent.active_matches[idx]
            if am.formation_period == 0
                agent.active_matches[idx] = ActiveMatch(am.partner_id, state.period,
                                                         am.is_principal, am.channel)
            end
        end
    end

    # ══════════════════════════════════════════════════════════════════════
    # Step 4: Learning and state updates
    # ══════════════════════════════════════════════════════════════════════

    # 4.1: Histories already recorded in sequential_match_formation!

    # 4.2: Satisfaction update
    update_satisfaction!(agents, accepted, demand_agent_ids, demand_channels, cal, p)

    # 4.3: Broker reputation
    update_broker_reputation!(broker, agents, broker_clients)

    # Record accumulators
    for m in accepted
        if m.channel == :self
            state.accum.n_self_matches += 1
            push!(state.accum.q_self, m.q_realized)
        elseif m.is_principal
            state.accum.n_broker_principal += 1
            push!(state.accum.q_broker_principal, m.q_realized)
            ask_j = counterparty_ask(agents[m.counterparty_id], cal.q_pub)
            profit = compute_principal_profit(m.q_realized, ask_j)
            state.accum.broker_principal_revenue += profit
            state.accum.cumulative_principal_revenue += profit
            broker.cumulative_revenue += profit
        else
            state.accum.n_broker_standard += 1
            push!(state.accum.q_broker_standard, m.q_realized)
            state.accum.broker_standard_revenue += cal.phi
            state.accum.cumulative_standard_revenue += cal.phi
            broker.cumulative_revenue += cal.phi
        end

        # Access vs assessment (uses pre-formation edge snapshot)
        if m.channel == :broker
            connected = false
            @inbounds for k in eachindex(wc_i)
                if wc_i[k] == m.demander_id && wc_j[k] == m.counterparty_id
                    connected = true; break
                end
            end
            if connected
                state.accum.assessment_count += 1
            else
                state.accum.access_count += 1
            end
        end
    end

    # Holdout evaluation (100 random pairs)
    n_holdout = 100
    if length(ws.Ax_buf) != d
        ws.Ax_buf = Vector{Float64}(undef, d)
        ws.Bx_buf = Vector{Float64}(undef, d)
        ws.holdout_z_buf = Vector{Float64}(undef, 2 * d)
    end
    Ax_buf = ws.Ax_buf; Bx_buf = ws.Bx_buf; z_buf = ws.holdout_z_buf
    for _ in 1:n_holdout
        i = rand(rng, 1:N)
        j = rand(rng, 1:N)
        i == j && continue

        q_true = Q_OFFSET + match_signal!(Ax_buf, Bx_buf, agents[i].type, agents[j].type, env)

        # Agent holdout (agent i predicts for partner j)
        q_hat_agent = predict_nn!(agents[i].nn, agents[i].predict_buf, agents[j].type)
        push!(state.accum.agent_holdout_pred, q_hat_agent)
        push!(state.accum.agent_holdout_real, q_true)

        # Broker holdout
        for k in 1:d
            z_buf[k] = agents[i].type[k]
            z_buf[d + k] = agents[j].type[k]
        end
        q_hat_broker = predict_nn!(broker.nn, broker.predict_buf, z_buf)
        push!(state.accum.broker_holdout_pred, q_hat_broker)
        push!(state.accum.broker_holdout_real, q_true)
    end

    state.accum.roster_size = length(broker.roster)

    # ══════════════════════════════════════════════════════════════════════
    # Step 5: Entry/exit
    # ══════════════════════════════════════════════════════════════════════
    process_entry_exit!(state, rng)

    # ══════════════════════════════════════════════════════════════════════
    # Step 6: Recording and measurement
    # ══════════════════════════════════════════════════════════════════════
    if state.period % p.network_measure_interval == 0
        update_cached_network_measures!(state)
    end

    return nothing
end
