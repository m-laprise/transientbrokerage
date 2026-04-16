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
using Graphs: neighbors, has_edge, rem_edge!
using LinearAlgebra: BLAS
using Base.Threads: @threads

# ─────────────────────────────────────────────────────────────────────────────

"""
    step_period!(state) -> Nothing

Execute one complete period of the simulation.
"""
agent_retrains_this_period(agent_id::Int, period::Int)::Bool = isodd(agent_id) == isodd(period)

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
    state.accum.broker_confidence_mae =
        broker.capture_confidence_ready ? broker.capture_confidence_mae : NaN

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

    broker_rep = broker_reputation(broker)

    for i in 1:N
        agents[i].periods_alive += 1
        avail_cap = available_capacity(agents[i], K)
        avail_cap <= 0 && continue

        d_i = rand(rng, Binomial(avail_cap, p.p_demand))
        d_i <= 0 && continue

        channel = outsourcing_decision(agents[i], agents, G, broker.node_id,
                                       broker_rep, d_i, cal.c_s, K, rng)

        push!(demand_agent_ids, i)
        push!(demand_channels, channel)
        push!(demand_counts, d_i)
        state.accum.n_demanders += 1
        state.accum.total_demand += d_i

        if channel == :broker
            push!(client_demands, (i, d_i))
            push!(broker_clients, i)
            state.accum.n_outsourced += 1
            agents[i].last_outsource_period = state.period
        end
    end

    # Rebuild roster: agents who outsourced within ROSTER_LAG periods.
    # Also maintain broker edges in G to match roster membership.
    empty!(broker.roster)
    for i in 1:N
        if is_on_roster(agents[i], state.period)
            push!(broker.roster, i)
            has_edge(G, i, broker.node_id) || add_broker_edge!(G, i, broker.node_id)
        else
            has_edge(G, i, broker.node_id) && rem_edge!(G, i, broker.node_id)
        end
    end

    # ══════════════════════════════════════════════════════════════════════
    # Step 2: Candidate evaluation
    # ══════════════════════════════════════════════════════════════════════

    # 2.1: Train neural networks (adaptive steps).
    # Agents retrain on an alternating parity schedule so each agent updates
    # every other period while still accumulating all new observations.
    # train_nn! materializes contiguous Matrix/Vector copies so train_step! sees
    # concrete types (no SubArray BLAS overhead).
    prev_blas = BLAS.get_num_threads()
    BLAS.set_num_threads(1)
    @threads for i in 1:N
        a = agents[i]
        a.history_count > 0 && a.n_new_obs > 0 &&
            agent_retrains_this_period(i, state.period) && train_agent_nn!(a, p)
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
        apply_mode_selection!(all_proposals, agents, broker, p, cal)
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
        # Selected-sample prediction quality (by channel)
        if m.channel == :self
            push!(state.accum.agent_predicted, m.q_predicted)
            push!(state.accum.agent_realized, m.q_realized)
        elseif m.channel == :broker
            push!(state.accum.broker_predicted, m.q_predicted)
            push!(state.accum.broker_realized, m.q_realized)
            state.accum.broker_error_abs_sum += abs(m.q_realized - m.q_predicted)
            state.accum.broker_error_count += 1
        end

        if m.channel == :self
            state.accum.n_self_matches += 1
            push!(state.accum.q_self, m.q_realized)
        elseif m.is_principal
            state.accum.n_broker_principal += 1
            push!(state.accum.q_broker_principal, m.q_realized)
            # §12h Step 4.3: capture-surplus ledger for this period.
            # q_predicted carries the broker's ex-ante q̂_b from allocation (§9 Step 2.3).
            # ask_j carries q̄_j from mode selection (§12c).
            push!(state.accum.q_bar_j_principal, m.ask_j)
            push!(state.accum.q_hat_b_principal, m.q_predicted)
            push!(state.accum.principal_acquired_ids, m.counterparty_id)
        else
            state.accum.n_broker_standard += 1
            push!(state.accum.q_broker_standard, m.q_realized)
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

    update_capture_confidence_mae!(broker,
                                   state.accum.broker_error_abs_sum,
                                   state.accum.broker_error_count,
                                   p.omega)

    # Holdout evaluation: per-agent R² averaged over sampled agents.
    # For each sampled agent i, evaluate both agent i's NN and the broker's NN
    # on the same n_partners random partners. Compute per-agent R² for each,
    # then average across agents. This makes the two metrics directly comparable.
    n_sample_agents = min(100, N)
    n_partners = 40

    if length(ws.Ax_buf) != d
        ws.Ax_buf = Vector{Float64}(undef, d)
        ws.Bx_buf = Vector{Float64}(undef, d)
        ws.holdout_z_buf = Vector{Float64}(undef, 2 * d)
    end
    Ax_buf = ws.Ax_buf; Bx_buf = ws.Bx_buf; z_buf = ws.holdout_z_buf

    agent_preds = Vector{Float64}(undef, n_partners)
    agent_trues = Vector{Float64}(undef, n_partners)
    broker_preds = Vector{Float64}(undef, n_partners)

    agent_r2_sum = 0.0; agent_bias_sum = 0.0; agent_rank_sum = 0.0; agent_rmse_sum = 0.0
    broker_r2_sum = 0.0; broker_bias_sum = 0.0; broker_rank_sum = 0.0; broker_rmse_sum = 0.0
    n_agents_evaluated = 0; n_broker_evaluated = 0

    for _ in 1:n_sample_agents
        i = rand(rng, 1:N)
        agents[i].history_count == 0 && continue  # exclude uninformed entrants
        n_valid = 0

        for _ in 1:n_partners
            j = rand(rng, 1:N)
            j == i && continue
            n_valid += 1

            q_true = Q_OFFSET + match_signal!(Ax_buf, Bx_buf, agents[i].type, agents[j].type, env)
            agent_preds[n_valid] = predict_nn!(agents[i].nn, agents[i].predict_buf, agents[j].type)
            agent_trues[n_valid] = q_true

            @inbounds for k in 1:d
                z_buf[k] = agents[i].type[k]
                z_buf[d + k] = agents[j].type[k]
            end
            broker_preds[n_valid] = predict_nn!(broker.nn, broker.predict_buf, z_buf)
        end

        if n_valid >= 5
            preds_v = agent_preds[1:n_valid]
            trues_v = agent_trues[1:n_valid]
            broker_v = broker_preds[1:n_valid]
            se = env.sigma_eps

            pq_agent = compute_prediction_quality(preds_v, trues_v; sigma_eps=se)
            if !isnan(pq_agent.r_squared)
                agent_r2_sum += pq_agent.r_squared
                agent_bias_sum += pq_agent.bias
                agent_rank_sum += pq_agent.rank_corr
                agent_rmse_sum += sqrt(mean((preds_v .- trues_v).^2))
                n_agents_evaluated += 1
            end

            pq_broker = compute_prediction_quality(broker_v, trues_v; sigma_eps=se)
            if !isnan(pq_broker.r_squared)
                broker_r2_sum += pq_broker.r_squared
                broker_bias_sum += pq_broker.bias
                broker_rank_sum += pq_broker.rank_corr
                broker_rmse_sum += sqrt(mean((broker_v .- trues_v).^2))
                n_broker_evaluated += 1
            end
        end
    end

    state.accum.agent_holdout_r2 = n_agents_evaluated > 0 ? agent_r2_sum / n_agents_evaluated : NaN
    state.accum.agent_holdout_bias = n_agents_evaluated > 0 ? agent_bias_sum / n_agents_evaluated : NaN
    state.accum.agent_holdout_rank = n_agents_evaluated > 0 ? agent_rank_sum / n_agents_evaluated : NaN
    state.accum.agent_holdout_rmse = n_agents_evaluated > 0 ? agent_rmse_sum / n_agents_evaluated : NaN
    state.accum.broker_holdout_r2 = n_broker_evaluated > 0 ? broker_r2_sum / n_broker_evaluated : NaN
    state.accum.broker_holdout_bias = n_broker_evaluated > 0 ? broker_bias_sum / n_broker_evaluated : NaN
    state.accum.broker_holdout_rank = n_broker_evaluated > 0 ? broker_rank_sum / n_broker_evaluated : NaN
    state.accum.broker_holdout_rmse = n_broker_evaluated > 0 ? broker_rmse_sum / n_broker_evaluated : NaN

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
