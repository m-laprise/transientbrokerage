"""
    matching.jl

Wage computation, conflict resolution, match finalization, satisfaction updates,
and match recording.
"""

"""
    compute_wage(q_hat, reservation_wage, beta_W) -> Float64

Wage = r_i + beta_W * max(q_hat - r_i, 0) per §3a.
"""
function compute_wage(q_hat::Float64, reservation_wage::Float64,
                      beta_W::Float64)::Float64
    return reservation_wage + beta_W * max(q_hat - reservation_wage, 0.0)
end

"""
    resolve_conflicts(proposals, rng) -> Vector{ProposedMatch}

Workers accept the highest-wage offer; ties broken randomly (§3.2.1).
"""
function resolve_conflicts(proposals::Vector{ProposedMatch},
                           rng::AbstractRNG)::Vector{ProposedMatch}
    isempty(proposals) && return ProposedMatch[]

    # Group by worker_id
    worker_proposals = Dict{Int, Vector{ProposedMatch}}()
    for p in proposals
        push!(get!(worker_proposals, p.worker_id, ProposedMatch[]), p)
    end

    accepted = ProposedMatch[]
    for (_, offers) in worker_proposals
        if length(offers) == 1
            push!(accepted, offers[1])
            continue
        end
        # Reservoir sampling over tied-best offers
        best_wage = -Inf
        winner = offers[1]
        n_tied = 0
        for o in offers
            if o.wage > best_wage
                best_wage = o.wage
                winner = o
                n_tied = 1
            elseif o.wage == best_wage
                n_tied += 1
                if rand(rng) < 1.0 / n_tied
                    winner = o
                end
            end
        end
        push!(accepted, winner)
    end
    return accepted
end

"""
    finalize_match!(match, state, z_buf, Ax_buf) -> Float64

Realize match output, update worker status, firm employees, histories, and satisfaction.
Returns realized output. `z_buf` and `Ax_buf` are pre-allocated buffers passed to `match_output!`.
"""
function finalize_match!(match::ProposedMatch, state::ModelState,
                         z_buf::Vector{Float64}, Ax_buf::Vector{Float64})::Float64
    worker = state.workers[match.worker_id]
    firm = state.firms[match.firm_idx]

    # Realize output
    q_realized = match_output!(z_buf, Ax_buf, worker.type, firm.type,
                                state.env, state.rng)

    # Update worker
    worker.status = employed
    worker.employer_id = firm.id
    push!(firm.employees, match.worker_id)

    # Record to firm history
    record_history!(firm, worker.type, q_realized)
    firm.hire_count += 1

    # Broker-specific: record to broker history, add worker to pool
    if match.source == :broker
        record_broker_history!(state.broker, worker.type, firm.type,
                               match.firm_idx, q_realized)
        push!(state.broker.pool, match.worker_id)
    end

    # Satisfaction update (§6a)
    r_i = worker.reservation_wage
    surplus_share = state.params.beta_W * max(match.q_hat_firm - r_i, 0.0)
    cost = if match.source == :broker
        surplus_share + state.params.alpha * match.wage / state.params.L
    else
        surplus_share
    end
    update_satisfaction!(firm, match.source, q_realized, state.params.omega;
                         cost_above_ri=cost)

    return q_realized
end

"""
    record_history!(firm, worker_type, q_realized)

Write a new observation to the firm's circular history buffer.
"""
function record_history!(firm::Firm, worker_type::AbstractVector{Float64},
                         q_realized::Float64)
    cap = size(firm.history_w, 2)
    firm.history_count += 1
    idx = mod1(firm.history_count, cap)
    firm.history_w[:, idx] = worker_type
    firm.history_q[idx] = q_realized
    return nothing
end

"""
    record_broker_history!(broker, worker_type, firm_type, firm_idx, q_realized)

Write a new observation to the broker's circular history buffer.
"""
function record_broker_history!(broker::Broker, worker_type::AbstractVector{Float64},
                                firm_type::AbstractVector{Float64},
                                firm_idx::Int, q_realized::Float64)
    cap = size(broker.history_w, 2)
    broker.history_count += 1
    idx = mod1(broker.history_count, cap)
    broker.history_w[:, idx] = worker_type
    broker.history_x[:, idx] = firm_type
    broker.history_q[idx] = q_realized
    broker.history_firm_idx[idx] = firm_idx
    return nothing
end

"""
    update_satisfaction!(firm, source, q_realized, omega; cost_above_ri=0.0)

EWMA update per §6a: s = (1-omega)*s + omega*(q_realized - cost_above_ri).
"""
function update_satisfaction!(firm::Firm, source::Symbol, q_realized::Float64,
                              omega::Float64; cost_above_ri::Float64 = 0.0)
    q_net = q_realized - cost_above_ri
    if source == :internal
        firm.satisfaction_internal = (1.0 - omega) * firm.satisfaction_internal + omega * q_net
        firm.tried_internal = true
    else
        firm.satisfaction_broker = (1.0 - omega) * firm.satisfaction_broker + omega * q_net
        firm.tried_broker = true
    end
    return nothing
end

"""
    penalize_no_proposal!(firm, omega)

No-proposal penalty per §6a: broker satisfaction updates toward internal satisfaction.
"""
function penalize_no_proposal!(firm::Firm, omega::Float64)
    firm.satisfaction_broker = (1.0 - omega) * firm.satisfaction_broker +
                               omega * firm.satisfaction_internal
    return nothing
end

"""
    record_match!(accum, source, in_referral_pool)

Increment match count. For brokered matches, classify as access (worker not in R_j)
or assessment (worker in R_j) per §8.
"""
function record_match!(accum::PeriodAccumulators, source::Symbol,
                       in_referral_pool::Bool)
    accum.matches += 1
    if source == :broker
        if in_referral_pool
            accum.assessment_count += 1
        else
            accum.access_count += 1
        end
    end
    return nothing
end
