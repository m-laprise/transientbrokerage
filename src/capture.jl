"""
    capture.jl

Resource capture (Model 1): principal-mode matching.
The broker decides per-match whether to act as a standard intermediary (earning φ)
or as a principal (stepping into the counterparty's role, earning the spread q_ij - q̄_j).

The broker acquires the counterparty's position at a price equal to the counterparty's
average realized match quality (its self-assessed value). No additional fee is charged
to the demander. The broker's profit is the spread between the match output and the
acquisition cost. The principal-mode hurdle is smoothed by:
- counterparty support: breadth of distinct prior demanders for counterparty j
- broker confidence: an EWMA of live realized broker-match absolute errors

Gated by params.enable_principal. When disabled, all brokered matches are standard.
"""

# ─────────────────────────────────────────────────────────────────────────────
# Counterparty ask price
# ─────────────────────────────────────────────────────────────────────────────

"""
    counterparty_ask(agent, q_cal) -> Float64

The counterparty's ask price: its average realized match quality from history,
or q_cal if it has no history. This is the minimum price the counterparty
accepts for selling its position to the broker.
"""
function counterparty_ask(agent::Agent, q_cal::Float64)::Float64
    n = agent.history_count
    n <= 0 && return q_cal
    total = 0.0
    @inbounds for i in 1:n
        total += agent.history_q[i]
    end
    return total / n
end

# ─────────────────────────────────────────────────────────────────────────────
# Mode decision
# ─────────────────────────────────────────────────────────────────────────────

"""
    capture_confidence_penalty(kappa, support_j, K) -> Float64

Smooth confidence penalty for principal mode:
    κ / sqrt(1 + s_j / K)
where κ is the broker's current realized-error scale and s_j is counterparty
support (distinct prior demanders for j). Scaling support by K makes the
penalty relax only after breadth has built up relative to the market's
per-period slot volume.
"""
function capture_confidence_penalty(kappa::Float64, support_j::Int, K::Int)::Float64
    return kappa / sqrt(1.0 + support_j / K)
end

"""
    broker_mode_decision(q_hat_b, ask_j, phi, kappa, support_j, K) -> Bool

Decide whether the broker operates in principal mode for a given match.
Returns true if the expected spread exceeds the standard placement fee:
    Π_principal = q̂_b - q̄_j > Π_standard = φ + κ / sqrt(1 + s_j / K)
"""
function broker_mode_decision(q_hat_b::Float64, ask_j::Float64,
                              phi::Float64, kappa::Float64,
                              support_j::Int, K::Int)::Bool
    return (q_hat_b - ask_j) > (phi + capture_confidence_penalty(kappa, support_j, K))
end

"""
    update_counterparty_support!(broker, demander_id, counterparty_id) -> Nothing

Record that demander i has been broker-matched with counterparty j. Support is
the count of distinct demanders previously matched with j.
"""
function update_counterparty_support!(broker::Broker, demander_id::Int,
                                      counterparty_id::Int)
    demander_id == counterparty_id && return nothing
    @inbounds if !broker.support_seen[demander_id, counterparty_id]
        broker.support_seen[demander_id, counterparty_id] = true
        broker.counterparty_support[counterparty_id] += 1
    end
    return nothing
end

"""
    clear_counterparty_support!(broker, agent_id) -> Nothing

Remove all support state touching a recycled agent slot. Row cleanup removes the
exiting agent as a prior demander; column cleanup clears the exiting agent as a
counterparty and resets its support count.
"""
function clear_counterparty_support!(broker::Broker, agent_id::Int)
    N = length(broker.counterparty_support)
    @inbounds for j in 1:N
        if broker.support_seen[agent_id, j]
            broker.support_seen[agent_id, j] = false
            broker.counterparty_support[j] -= 1
        end
        broker.support_seen[j, agent_id] = false
    end
    broker.counterparty_support[agent_id] = 0
    return nothing
end

"""
    update_capture_confidence_mae!(broker, abs_error_sum, n_errors, omega) -> Nothing

Update the broker's live confidence scale from realized broker-match absolute
errors. If confidence has not yet been initialized, the first period with any
broker-realized matches sets κ directly to that period MAE. No-op when there are
no broker-realized matches in the period, so capture remains disabled until the
first live broker period with data.
"""
function update_capture_confidence_mae!(broker::Broker,
                                        abs_error_sum::Float64,
                                        n_errors::Int,
                                        omega::Float64)
    n_errors <= 0 && return nothing
    current_mae = abs_error_sum / n_errors
    if !broker.capture_confidence_ready
        broker.capture_confidence_mae = current_mae
        broker.capture_confidence_ready = true
    else
        broker.capture_confidence_mae =
            (1.0 - omega) * broker.capture_confidence_mae + omega * current_mae
    end
    return nothing
end

"""
    apply_mode_selection!(proposals, agents, broker, params, cal)

Mark broker proposals as principal-mode where profitable after the smooth
support/confidence penalty (§12c). Caches the acquisition reservation `ask_j` =
q̄_j on the principal-mode proposal so that capture surplus at acceptance time
uses the same reservation the broker used for its mode decision (avoiding drift
from within-period history updates). Only applies when params.enable_principal
is true and the broker has already observed at least one live broker period with
realized match errors.
"""
function apply_mode_selection!(proposals::Vector{ProposedMatch},
                               agents::Vector{Agent},
                               broker::Broker,
                               params::ModelParams,
                               cal::CalibrationConstants)
    (params.enable_principal && broker.capture_confidence_ready) || return proposals

    for idx in eachindex(proposals)
        pm = proposals[idx]
        pm.channel == :broker || continue

        ask_j = counterparty_ask(agents[pm.counterparty_id], cal.q_cal)
        support_j = broker.counterparty_support[pm.counterparty_id]
        if broker_mode_decision(pm.evaluation, ask_j, cal.phi,
                                broker.capture_confidence_mae, support_j, params.K)
            proposals[idx] = ProposedMatch(
                pm.demander_id, pm.counterparty_id,
                pm.channel, pm.evaluation, true, ask_j
            )
        end
    end

    return proposals
end

# ─────────────────────────────────────────────────────────────────────────────
# Capture surplus
# ─────────────────────────────────────────────────────────────────────────────

"""
    capture_surplus(q_realized, ask_j) -> Float64

Capture surplus Δq_{ij} = q_{ij} - q̄_j (§12b): the realized match output net of
the counterparty's acquisition reservation. Positive when the acquired position
outperforms the counterparty's self-assessed value; negative realizations
represent the broker's capture risk (§12d).
"""
function capture_surplus(q_realized::Float64, ask_j::Float64)::Float64
    return q_realized - ask_j
end
