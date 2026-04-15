"""
    matching.jl

Sequential match formation, satisfaction tracking, and outsourcing decision.
No wages in v0.2: match economics use fixed fees (phi, c_s) and the outside option r.
Under principal mode (Model 1), the broker's compensation is the spread q_ij - ask_j.
"""

using Random: AbstractRNG, shuffle!
using Graphs: has_edge, neighbors, SimpleGraph

# ─────────────────────────────────────────────────────────────────────────────
# Sequential match formation (§9 Step 3)
# ─────────────────────────────────────────────────────────────────────────────

"""
    sequential_match_formation!(proposals, agents, broker, env, G, params, cal, rng)
        -> Vector{NamedTuple}

Process all proposals in random order. Check both sides' capacity; counterparty
evaluates independently (history average for known neighbors, NN prediction for
strangers). Returns a vector of accepted match records.

Each accepted match record is a NamedTuple with fields:
  demander_id, counterparty_id, channel, is_principal, q_realized, q_predicted
"""
function sequential_match_formation!(proposals::Vector{ProposedMatch},
                                      agents::Vector{Agent},
                                      broker::Broker,
                                      env::MatchingEnv,
                                      G::SimpleGraph,
                                      params::ModelParams,
                                      cal::CalibrationConstants,
                                      rng::AbstractRNG)
    accepted = NamedTuple{(:demander_id, :counterparty_id, :channel, :is_principal, :q_realized, :q_predicted, :ask_j),
                          Tuple{Int, Int, Symbol, Bool, Float64, Float64, Float64}}[]
    isempty(proposals) && return accepted

    N = length(agents)
    K = params.K
    d = params.d
    broker_node = broker.node_id

    # Pre-allocated buffers for match_output! (avoid alloc per match)
    Ax_buf = Vector{Float64}(undef, d)
    Bx_buf = Vector{Float64}(undef, d)

    # Mutable capacity counters (decremented on acceptance)
    remaining_cap = [available_capacity(agents[i], K) for i in 1:N]

    # Shuffle proposals
    shuffle!(rng, proposals)

    for pm in proposals
        i = pm.demander_id
        j = pm.counterparty_id

        # Check both sides have capacity
        remaining_cap[i] <= 0 && continue
        remaining_cap[j] <= 0 && continue

        if pm.is_principal
            # Principal mode: counterparty acceptance is automatic (broker pays r)
            # Demander's participation constraint was applied during broker allocation
        else
            # Counterparty evaluates independently
            counterparty_eval = if has_edge(G, j, i) && agents[j].partner_count[i] > 0
                # Known neighbor: use historical average
                partner_mean(agents[j], i)
            else
                # Stranger: use NN prediction
                predict_nn!(agents[j].nn, agents[j].predict_buf, agents[i].type)
            end

            # Participation constraint
            counterparty_eval <= cal.r && continue
        end

        # ── Accept the match ──

        # Realize output
        q_realized = match_output!(Ax_buf, Bx_buf, agents[i].type, agents[j].type, env, rng)

        # Decrement capacity
        remaining_cap[i] -= 1
        remaining_cap[j] -= 1

        if pm.is_principal
            # Principal mode: broker learns, agents don't, no edge
            record_broker_history!(broker, agents[i].type, agents[j].type, q_realized)
            # Active match entries (both sides)
            push!(agents[i].active_matches, ActiveMatch(j, 0, true, :broker))  # period filled in step.jl
            push!(agents[j].active_matches, ActiveMatch(i, 0, true, :broker))
            # §12h Step 4.1: counterparty j was the acquired counterparty
            agents[j].n_principal_acquired += 1
        else
            # Standard match: both parties learn, edge forms
            record_agent_history!(agents[i], agents[j].type, q_realized)
            record_agent_history!(agents[j], agents[i].type, q_realized)
            update_partner_mean!(agents[i], j, q_realized)
            update_partner_mean!(agents[j], i, q_realized)
            if pm.channel == :broker
                record_broker_history!(broker, agents[i].type, agents[j].type, q_realized)
                # Record pair for familiarity-gated capture (principal mode)
                push!(broker.familiar_pairs, (min(i, j), max(i, j)))
            end
            add_match_edge!(G, i, j)
            push!(agents[i].active_matches, ActiveMatch(j, 0, false, pm.channel))
            push!(agents[j].active_matches, ActiveMatch(i, 0, false, pm.channel))
        end

        # §12h Step 4.1: cumulative match counter (any role, any channel).
        # Feeds D_j = n_principal_acquired / n_matches_any in collect_period_metrics (§12i).
        agents[i].n_matches_any += 1
        agents[j].n_matches_any += 1

        push!(accepted, (demander_id=i, counterparty_id=j, channel=pm.channel,
                         is_principal=pm.is_principal, q_realized=q_realized,
                         q_predicted=pm.evaluation, ask_j=pm.ask_j))
    end

    return accepted
end

# ─────────────────────────────────────────────────────────────────────────────
# Satisfaction tracking (§6a)
# ─────────────────────────────────────────────────────────────────────────────

"""
    update_satisfaction!(agents, accepted_matches, demand_agent_ids, demand_channels, cal, params)

Update satisfaction indices for all agents that had demand this period.
Multiple same-channel outcomes are averaged into a single EWMA update.
No-match penalty (decay toward zero) if all slots through a channel failed.
"""
function update_satisfaction!(agents::Vector{Agent},
                              accepted_matches::Vector{<:NamedTuple},
                              demand_agent_ids::Vector{Int},
                              demand_channels::Vector{Symbol},
                              cal::CalibrationConstants,
                              params::ModelParams)
    omega = params.omega

    # Group accepted matches by demander: accumulate sum and count per agent
    demander_sum = Dict{Int, Float64}()
    demander_count = Dict{Int, Int}()
    for m in accepted_matches
        i = m.demander_id
        cost = if m.channel == :self
            cal.c_s
        elseif m.is_principal
            0.0
        else
            cal.phi
        end
        tilde_q = m.q_realized - cost
        demander_sum[i] = get(demander_sum, i, 0.0) + tilde_q
        demander_count[i] = get(demander_count, i, 0) + 1
    end

    # Update each agent that had demand
    for idx in eachindex(demand_agent_ids)
        agent_id = demand_agent_ids[idx]
        channel = demand_channels[idx]
        agent = agents[agent_id]
        n_matched = get(demander_count, agent_id, 0)

        if n_matched > 0
            tilde_q = demander_sum[agent_id] / n_matched
            if channel == :self
                agent.satisfaction_self = (1.0 - omega) * agent.satisfaction_self + omega * tilde_q
            else
                agent.satisfaction_broker = (1.0 - omega) * agent.satisfaction_broker + omega * tilde_q
                agent.tried_broker = true
            end
        else
            if channel == :self
                agent.satisfaction_self *= (1.0 - omega)
            else
                agent.satisfaction_broker *= (1.0 - omega)
                agent.tried_broker = true
            end
        end
    end

    return nothing
end

# ─────────────────────────────────────────────────────────────────────────────
# Outsourcing decision (§6b)
# ─────────────────────────────────────────────────────────────────────────────

"""
    outsourcing_decision(agent, agents, G, broker_node, broker_rep, d_i, c_s, K, rng) -> Symbol

Agent chooses :self or :broker. Compares three scores:
- score_self: EWMA satisfaction from past self-search outcomes
- score_known: average of the best d_i known partners' quality minus c_s
  (opportunity cost: "I already know good partners from prior matches")
- score_broker: EWMA broker satisfaction, or broker reputation if untried

The agent outsources only if the broker beats both historical self-search
satisfaction and the value of directly reaching known good partners.
"""
function outsourcing_decision(agent::Agent, agents::Vector{Agent},
                              G::SimpleGraph, broker_node::Int,
                              broker_rep::Float64, d_i::Int, c_s::Float64,
                              K::Int, rng::AbstractRNG)::Symbol
    score_self = agent.satisfaction_self
    score_broker = agent.tried_broker ? agent.satisfaction_broker : broker_rep

    # Opportunity cost: best known partners the agent could reach directly.
    # Collect partner_means for neighbors with capacity, take top d_i, average.
    nbr_vals = Float64[]
    for nbr in neighbors(G, agent.id)
        nbr == broker_node && continue
        (nbr < 1 || nbr > length(agents)) && continue
        available_capacity(agents[nbr], K) <= 0 && continue
        m = partner_mean(agent, nbr)
        isnan(m) || push!(nbr_vals, m)
    end

    score_known = if isempty(nbr_vals)
        -Inf  # no known partners with capacity
    else
        sort!(nbr_vals; rev=true)
        n_use = min(d_i, length(nbr_vals))
        sum(nbr_vals[k] for k in 1:n_use) / d_i - c_s
        # Dividing by d_i (not n_use): if agent needs 3 slots but only knows 1
        # good partner, the average is diluted by zeros for unfilled slots.
    end

    score_floor = max(score_self, score_known)

    if score_floor > score_broker
        return :self
    elseif score_broker > score_floor
        return :broker
    else
        return rand(rng) < 0.5 ? :self : :broker
    end
end

# ─────────────────────────────────────────────────────────────────────────────
# Broker reputation (§6c)
# ─────────────────────────────────────────────────────────────────────────────

"""
    broker_reputation(broker) -> Float64

Return the broker's current reputation for untried agents.
Returns 0 if the broker has never had clients (should not occur after initialization).
"""
function broker_reputation(broker::Broker)::Float64
    return broker.last_reputation  # 0.0 if never had clients, else mean client satisfaction
end

"""
    update_broker_reputation!(broker, agents, client_ids)

Update broker reputation to mean broker satisfaction of current clients.
If no clients this period, hold previous value.
"""
function update_broker_reputation!(broker::Broker, agents::Vector{Agent},
                                   client_ids::AbstractVector{Int})
    isempty(client_ids) && return nothing
    total = 0.0
    @inbounds for cid in client_ids
        total += agents[cid].satisfaction_broker
    end
    broker.last_reputation = total / length(client_ids)
    broker.has_had_clients = true
    return nothing
end
