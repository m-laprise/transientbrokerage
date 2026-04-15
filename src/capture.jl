"""
    capture.jl

Resource capture (Model 1): principal-mode matching.
The broker decides per-match whether to act as a standard intermediary (earning φ)
or as a principal (stepping into the counterparty's role, earning the spread q_ij - q̄_j).

The broker acquires the counterparty's position at a price equal to the counterparty's
average realized match quality (its self-assessed value). No additional fee is charged
to the demander. The broker's profit is the spread between the match output and the
acquisition cost.

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
    broker_mode_decision(q_hat_b, ask_j, phi) -> Bool

Decide whether the broker operates in principal mode for a given match.
Returns true if the expected spread exceeds the standard placement fee:
    Π_principal = q̂_b - q̄_j > Π_standard = φ
"""
function broker_mode_decision(q_hat_b::Float64, ask_j::Float64, phi::Float64)::Bool
    return (q_hat_b - ask_j) > phi
end

"""
    apply_mode_selection!(proposals, agents, broker, params, cal)

Mark broker proposals as principal-mode where profitable AND the broker has
previously matched this specific pair through standard placement (familiarity
requirement, §12c). Caches the acquisition reservation `ask_j` = q̄_j on the
principal-mode proposal so that capture surplus at acceptance time uses the
same reservation the broker used for its mode decision (avoiding drift from
within-period history updates). Only applies when params.enable_principal is true.
"""
function apply_mode_selection!(proposals::Vector{ProposedMatch},
                               agents::Vector{Agent},
                               broker::Broker,
                               params::ModelParams,
                               cal::CalibrationConstants)
    params.enable_principal || return proposals

    for idx in eachindex(proposals)
        pm = proposals[idx]
        pm.channel == :broker || continue

        # Familiarity gate: broker must have matched this pair before
        lo = min(pm.demander_id, pm.counterparty_id)
        hi = max(pm.demander_id, pm.counterparty_id)
        (lo, hi) in broker.familiar_pairs || continue

        ask_j = counterparty_ask(agents[pm.counterparty_id], cal.q_cal)
        if broker_mode_decision(pm.evaluation, ask_j, cal.phi)
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
