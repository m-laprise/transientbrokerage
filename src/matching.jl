"""
    matching.jl

Sequential match formation, satisfaction tracking, and outsourcing decision.
No wages in v0.2: match economics use fixed fees (phi, c_s) and the outside option r.
Under principal mode (Model 1), the broker's compensation is the spread q_ij - ask_j.
"""

using Random: AbstractRNG, shuffle!
using Graphs: has_edge

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
    accepted = NamedTuple{(:demander_id, :counterparty_id, :channel, :is_principal, :q_realized, :q_predicted),
                          Tuple{Int, Int, Symbol, Bool, Float64, Float64}}[]
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
        else
            # Standard match: both parties learn, edge forms
            record_agent_history!(agents[i], agents[j].type, q_realized)
            record_agent_history!(agents[j], agents[i].type, q_realized)
            update_partner_mean!(agents[i], j, q_realized)
            update_partner_mean!(agents[j], i, q_realized)
            if pm.channel == :broker
                record_broker_history!(broker, agents[i].type, agents[j].type, q_realized)
            end
            add_match_edge!(G, i, j)
            push!(agents[i].active_matches, ActiveMatch(j, 0, false, pm.channel))
            push!(agents[j].active_matches, ActiveMatch(i, 0, false, pm.channel))
        end

        push!(accepted, (demander_id=i, counterparty_id=j, channel=pm.channel,
                         is_principal=pm.is_principal, q_realized=q_realized,
                         q_predicted=pm.evaluation))
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
    outsourcing_decision(agent, broker_rep, rng) -> Symbol

Agent chooses :self or :broker based on satisfaction scores.
If agent has never tried the broker, substitutes broker reputation.
"""
function outsourcing_decision(agent::Agent, broker_rep::Float64,
                              rng::AbstractRNG)::Symbol
    score_self = agent.satisfaction_self
    score_broker = agent.tried_broker ? agent.satisfaction_broker : broker_rep

    if score_self > score_broker
        return :self
    elseif score_broker > score_self
        return :broker
    else
        return rand(rng) < 0.5 ? :self : :broker
    end
end

# ─────────────────────────────────────────────────────────────────────────────
# Broker reputation (§6c)
# ─────────────────────────────────────────────────────────────────────────────

"""
    broker_reputation(broker, q_pub) -> Float64

Return the broker's current reputation for untried agents.
"""
function broker_reputation(broker::Broker, q_pub::Float64)::Float64
    return broker.has_had_clients ? broker.last_reputation : q_pub
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
