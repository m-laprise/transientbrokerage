"""
    step.jl

Main simulation loop: one period of the model (§9, Steps 0-6).

Step 0: Current-period match reset
Step 1: Demand generation and outsourcing decisions
Step 2: Candidate evaluation (train NNs and pre-period capture planning)
Step 3: Within-period round-based match formation
Step 4: Learning updates (histories already recorded in Step 3; satisfaction, reputation)
Step 5: Entry/exit
Step 6: Recording and measurement
"""

using Random: AbstractRNG, shuffle!
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

function refresh_broker_roster!(state::ModelState)
    p = state.params
    broker = state.broker
    rng = state.rng
    N = p.N
    target_size = roster_target_size(N)

    if p.roster_churn > 0.0 && !isempty(broker.roster)
        for rid in collect(broker.roster)
            rand(rng) < p.roster_churn && delete!(broker.roster, rid)
        end
    end

    n_missing = target_size - length(broker.roster)
    if n_missing > 0
        candidates = Int[]
        sizehint!(candidates, max(N - length(broker.roster), 0))
        for i in 1:N
            (i in broker.roster) && continue
            push!(candidates, i)
        end
        shuffle!(rng, candidates)
        for idx in 1:min(n_missing, length(candidates))
            push!(broker.roster, candidates[idx])
        end
    end

    sync_broker_edges!(state.G, state.agents, broker)
    return nothing
end

function prefix_rmse(predicted::AbstractVector{<:Real},
                     realized::AbstractVector{<:Real},
                     n::Int)::Float64
    sq_err_sum = 0.0
    @inbounds for idx in 1:n
        err = predicted[idx] - realized[idx]
        sq_err_sum += err * err
    end
    return sqrt(sq_err_sum / n)
end

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
    ws = state.workspace

    reset_accumulators!(state.accum)
    state.accum.broker_confidence_mae =
        broker.capture_confidence_ready ? broker.capture_confidence_mae : NaN

    # ══════════════════════════════════════════════════════════════════════
    # Step 0: Current-period match reset
    # ══════════════════════════════════════════════════════════════════════
    for agent in agents
        empty!(agent.active_matches)
    end
    reset_principal_inventory!(ws, N)

    # Clear the current-client overlay from the prior period, then refresh the
    # standing roster after prior-period turnover and before current-period
    # demand realization.
    empty!(broker.current_clients)
    refresh_broker_roster!(state)

    # ══════════════════════════════════════════════════════════════════════
    # Step 1: Demand generation and outsourcing decisions
    # ══════════════════════════════════════════════════════════════════════
    # Reuse workspace vectors (avoid Dict/Set allocation every period)
    demand_agent_ids = ws.demand_agent_ids; empty!(demand_agent_ids)
    demand_channels = ws.demand_channels; empty!(demand_channels)
    demand_counts = ws.demand_counts; empty!(demand_counts)
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
            push!(broker_clients, i)
            push!(broker.current_clients, i)
            state.accum.n_outsourced += 1
            state.accum.outsourced_slots += d_i
        end
    end
    sync_broker_edges!(G, agents, broker)

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

    # 2.2: Literal same-period acquisition planning (Model 1)
    plan_period_capture!(demand_agent_ids, demand_channels, demand_counts,
                         agents, broker, p, cal; ws=ws)

    # 2.3: Within-period round-based principal execution and residual match formation
    accepted = round_match_formation!(demand_agent_ids, demand_channels, demand_counts,
                                      agents, broker, env, G, p, cal, rng;
                                      ws=ws, accepted_matches=ws.accepted_matches)
    sync_broker_edges!(G, agents, broker)

    # ══════════════════════════════════════════════════════════════════════
    # Step 4: Learning and state updates
    # ══════════════════════════════════════════════════════════════════════

    # 4.1: Histories already recorded during round_match_formation!

    # 4.2: Satisfaction update
    update_satisfaction!(agents, accepted, demand_agent_ids, demand_channels, demand_counts, cal, p;
                         demander_sum=ws.demander_q_sum,
                         broker_standard_count=ws.broker_standard_count)

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
            exposure_qhat = m.is_principal ? m.capture_qhat : m.q_predicted
            state.accum.broker_error_abs_sum += abs(m.q_realized - exposure_qhat)
            state.accum.broker_error_count += 1
        end

        if m.channel == :self
            state.accum.n_self_matches += 1
            push!(state.accum.q_self, m.q_realized)
        elseif m.is_principal
            state.accum.n_broker_principal += 1
            push!(state.accum.q_broker_principal, m.q_realized)
            push!(state.accum.capture_realized, m.q_realized)
            push!(state.accum.capture_ask, m.ask_j)
            push!(state.accum.capture_qhat, m.capture_qhat)
        else
            state.accum.n_broker_standard += 1
            push!(state.accum.q_broker_standard, m.q_realized)
        end

        # Access vs assessment (uses per-round pre-finalization edge snapshots)
        wc_i = ws.was_connected_i
        wc_j = ws.was_connected_j
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

    for counterparty_id in ws.principal_inventory_ids
        push!(state.accum.principal_acquired_ids, counterparty_id)
    end
    @inbounds for block_idx in eachindex(ws.principal_inventory_ids)
        ask_j = ws.principal_inventory_asks[block_idx]
        qhats = ws.principal_inventory_slot_qhats[block_idx]
        next_slot = ws.principal_inventory_next_slot[block_idx]
        for slot_idx in next_slot:length(qhats)
            qhat = qhats[slot_idx]
            push!(state.accum.capture_realized, 0.0)
            push!(state.accum.capture_ask, ask_j)
            push!(state.accum.capture_qhat, qhat)
            state.accum.broker_error_abs_sum += abs(qhat)
            state.accum.broker_error_count += 1
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

    if length(ws.Ax_buf) != d || length(ws.Bx_buf) != d || length(ws.holdout_z_buf) != 2 * d
        ws.Ax_buf = Vector{Float64}(undef, d)
        ws.Bx_buf = Vector{Float64}(undef, d)
        ws.holdout_z_buf = Vector{Float64}(undef, 2 * d)
    end
    length(ws.holdout_agent_preds) == n_partners || resize!(ws.holdout_agent_preds, n_partners)
    length(ws.holdout_agent_trues) == n_partners || resize!(ws.holdout_agent_trues, n_partners)
    length(ws.holdout_broker_preds) == n_partners || resize!(ws.holdout_broker_preds, n_partners)
    Ax_buf = ws.Ax_buf; Bx_buf = ws.Bx_buf; z_buf = ws.holdout_z_buf
    agent_preds = ws.holdout_agent_preds
    agent_trues = ws.holdout_agent_trues
    broker_preds = ws.holdout_broker_preds

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
            preds_v = @view agent_preds[1:n_valid]
            trues_v = @view agent_trues[1:n_valid]
            broker_v = @view broker_preds[1:n_valid]
            se = env.sigma_eps

            pq_agent = compute_prediction_quality(preds_v, trues_v; sigma_eps=se)
            if !isnan(pq_agent.r_squared)
                agent_r2_sum += pq_agent.r_squared
                agent_bias_sum += pq_agent.bias
                agent_rank_sum += pq_agent.rank_corr
                agent_rmse_sum += prefix_rmse(agent_preds, agent_trues, n_valid)
                n_agents_evaluated += 1
            end

            pq_broker = compute_prediction_quality(broker_v, trues_v; sigma_eps=se)
            if !isnan(pq_broker.r_squared)
                broker_r2_sum += pq_broker.r_squared
                broker_bias_sum += pq_broker.bias
                broker_rank_sum += pq_broker.rank_corr
                broker_rmse_sum += prefix_rmse(broker_preds, agent_trues, n_valid)
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
    state.accum.broker_access_size = broker_access_size(broker)

    # ══════════════════════════════════════════════════════════════════════
    # Step 5: Entry/exit
    # ══════════════════════════════════════════════════════════════════════
    process_entry_exit!(state, rng)
    sync_broker_edges!(G, agents, broker)

    # ══════════════════════════════════════════════════════════════════════
    # Step 6: Recording and measurement
    # ══════════════════════════════════════════════════════════════════════
    if state.period % p.network_measure_interval == 0
        update_cached_network_measures!(state)
    end

    return nothing
end
