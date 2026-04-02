"""
    staffing.jl

Model 1: staffing decisions, assignment creation, per-period economics, and
expiration processing (§9). Guarded by `params.enable_staffing` in `step.jl`.
"""

"""
    broker_prefers_staffing(q_hat_b, r_i, params, r_base) -> Bool

True when expected staffing profit L·(μ_b·q̂_b − c_emp) exceeds estimated
placement profit α·ŵ, where ŵ uses q̂_b as proxy for unknown q̂_j (§9d).
"""
function broker_prefers_staffing(q_hat_b::Float64, r_i::Float64,
                                 params::ModelParams, r_base::Float64)::Bool
    c_emp = params.c_emp_frac * r_base
    staff_profit = params.L * (params.mu_b * q_hat_b - c_emp)
    estimated_wage = r_i + params.beta_W * max(q_hat_b - r_i, 0.0)
    place_profit = params.alpha * estimated_wage
    return staff_profit > place_profit
end

"""
    firm_accepts_staffing(q_hat_b, q_hat_j, r_i, params) -> Bool

Firm accepts when bill rate r_i + μ_b·q̂_b ≤ amortized direct-hire cost ŵ_j·(1+α/L) (§9e).
"""
function firm_accepts_staffing(q_hat_b::Float64, q_hat_j::Float64,
                                r_i::Float64, params::ModelParams)::Bool
    bill_rate = r_i + params.mu_b * q_hat_b
    wage_j = r_i + params.beta_W * max(q_hat_j - r_i, 0.0)
    direct_cost = wage_j * (1.0 + params.alpha / params.L)
    return bill_rate <= direct_cost
end

"""
    create_staffing_assignment!(state, proposed, q_hat_b) -> Float64

Finalize an accepted staffing match (§9g). Realizes output once, creates the
assignment, records to broker history, and updates firm satisfaction. Returns
realized output. Does NOT update firm employees or history (lock-in, §9f).
Per-period surplus is accumulated by `process_staffing_economics!`, not here.
"""
function create_staffing_assignment!(state::ModelState, proposed::ProposedMatch,
                                     q_hat_b::Float64)::Float64
    worker = state.workers[proposed.worker_id]
    firm = state.firms[proposed.firm_idx]
    params = state.params

    # Realize output once (§9g step 3.3.1)
    q_realized = match_output(worker.type, firm.type, state.env, state.rng)

    # Worker status → staffed
    worker.status = staffed
    worker.broker_id = state.broker.id
    worker.staffing_firm_id = firm.id

    # Create assignment
    r_i = worker.reservation_wage
    bill_rate = r_i + params.mu_b * q_hat_b
    push!(state.broker.active_assignments,
          StaffingAssignment(proposed.worker_id, proposed.firm_idx, firm.id,
                             params.L, r_i, bill_rate, q_realized, q_hat_b))

    # Broker learns from staffing (§9a)
    record_broker_history!(state.broker, worker.type, firm.type,
                           proposed.firm_idx, q_realized)

    # Satisfaction update with staffing cost (§9c, §9g step 4.2)
    update_satisfaction!(firm, :broker, q_realized, params.omega;
                         cost_above_ri=params.mu_b * q_hat_b)

    # Lock-in: firm.employees and firm history are NOT updated (§9f)
    return q_realized
end

"""Reset a staffed worker to available, clearing `broker_id` and `staffing_firm_id`."""
function release_staffed_worker!(workers::Vector{Worker}, worker_id::Int)
    w = workers[worker_id]
    w.status = available
    w.broker_id = 0
    w.staffing_firm_id = 0
    return nothing
end

"""
    process_staffing_economics!(state)

Per-period processing of all active staffing assignments. For each assignment:
accumulate surplus and broker revenue, decrement `periods_remaining`, and expire
completed assignments (worker → available, vacancy reopens). Handles all L periods
uniformly, including period 1 for newly created assignments (§9g step 4.4).
"""
function process_staffing_economics!(state::ModelState)
    assignments = state.broker.active_assignments
    params = state.params
    a = state.accum
    c_emp = params.c_emp_frac * state.cal.r_base
    mu_b = params.mu_b

    i = length(assignments)
    while i >= 1
        sa = assignments[i]

        # Per-period surplus and revenue
        mu_q = mu_b * sa.predicted_q
        a.total_realized_surplus += sa.realized_q - sa.reservation_wage
        a.firm_surplus_staffed += sa.realized_q - sa.reservation_wage - mu_q
        a.broker_surplus_staffing += mu_q
        a.n_active_staffing += 1
        a.staffing_revenue += mu_q - c_emp
        a.cumulative_staffing_revenue += mu_q - c_emp

        # Decrement and check expiration
        sa.periods_remaining -= 1
        if sa.periods_remaining <= 0
            release_staffed_worker!(state.workers, sa.worker_id)
            if sa.firm_idx ∉ state.open_vacancies
                push!(state.open_vacancies, sa.firm_idx)
            end
            # Swap-delete for O(1) removal
            assignments[i] = assignments[end]
            pop!(assignments)
        end
        i -= 1
    end
    return nothing
end

"""
    terminate_firm_assignments!(state, firm_idx, avail)

Terminate all staffing assignments at firm `firm_idx` (§9g step 5.1). Workers
return to available and are added to `avail`. Called by `exit_firm!`.
"""
function terminate_firm_assignments!(state::ModelState, firm_idx::Int, avail::Set{Int})
    assignments = state.broker.active_assignments
    i = length(assignments)
    while i >= 1
        if assignments[i].firm_idx == firm_idx
            wid = assignments[i].worker_id
            release_staffed_worker!(state.workers, wid)
            push!(avail, wid)
            assignments[i] = assignments[end]
            pop!(assignments)
        end
        i -= 1
    end
    return nothing
end
