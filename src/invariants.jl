"""
    invariants.jl

Debug-time state consistency checks. Disable in production runs for performance.
"""

"""
    verify_invariants(state)

Assert that the simulation state is internally consistent. Checks worker
conservation, no double-employment, status consistency, vacancy counts in [0,2],
broker pool (all members available, size <= target P), staffing assignment
consistency, finite satisfaction, and reservation wage floor.
Intended for use in test runs; disable in production.
"""
function verify_invariants(state::ModelState)
    N_W = state.params.N_W

    # Population counts
    @assert length(state.workers) == N_W "Expected $N_W workers, got $(length(state.workers))"

    n_available = count(w -> w.status == available, state.workers)
    n_employed = count(w -> w.status == employed, state.workers)
    n_staffed = count(w -> w.status == staffed, state.workers)
    @assert n_available + n_employed + n_staffed == N_W "Worker count not conserved: $n_available + $n_employed + $n_staffed != $N_W"

    # No double-employment
    seen = Set{Int}()
    for firm in state.firms
        for wid in firm.employees
            @assert wid ∉ seen "Worker $wid employed by two firms"
            push!(seen, wid)
        end
    end

    # Worker-firm status consistency
    for firm in state.firms
        for wid in firm.employees
            w = state.workers[wid]
            @assert w.status == employed "Worker $wid in firm $(firm.id) employees but status=$(w.status)"
            @assert w.employer_id == firm.id "Worker $wid in firm $(firm.id) employees but employer_id=$(w.employer_id)"
        end
    end

    # Available workers have no employer
    for w in state.workers
        if w.status == available
            @assert w.employer_id == 0 "Available worker $(w.id) has employer_id=$(w.employer_id)"
        end
    end

    # Open vacancies: vector length matches firms, counts in [0, 2]
    @assert length(state.open_vacancies) == length(state.firms) "open_vacancies length mismatch"
    for j in eachindex(state.open_vacancies)
        @assert 0 <= state.open_vacancies[j] <= 2 "Vacancy count $(state.open_vacancies[j]) out of range for firm $j"
    end

    # Broker pool: all members available, size <= target P
    # Pool may be empty if all workers are employed (no available workers to recruit)
    P = ceil(Int, state.params.pool_target_frac * state.params.N_W)
    @assert length(state.broker.pool) <= P "Broker pool size $(length(state.broker.pool)) > target $P"
    for wid in state.broker.pool
        @assert state.workers[wid].status == available "Pool member $wid has status=$(state.workers[wid].status)"
    end

    # Staffing assignment consistency
    staffed_by_assignment = Set{Int}()
    for assignment in state.broker.active_assignments
        w = state.workers[assignment.worker_id]
        @assert w.status == staffed "Staffed worker $(assignment.worker_id) has status=$(w.status)"
        @assert assignment.periods_remaining > 0 "Assignment for worker $(assignment.worker_id) has periods_remaining=$(assignment.periods_remaining)"
        @assert 1 <= assignment.firm_idx <= length(state.firms) "Assignment firm_idx $(assignment.firm_idx) out of bounds"
        # Lock-in: staffed worker must NOT be in any firm's employee set
        @assert assignment.worker_id ∉ state.firms[assignment.firm_idx].employees "Staffed worker $(assignment.worker_id) found in firm $(assignment.firm_idx) employees (lock-in violated)"
        push!(staffed_by_assignment, assignment.worker_id)
    end
    # Every staffed worker must have a corresponding assignment
    for w in state.workers
        if w.status == staffed
            @assert w.id in staffed_by_assignment "Worker $(w.id) has status=staffed but no active assignment"
        end
    end
    # No staffed worker in broker pool
    for wid in state.broker.pool
        @assert state.workers[wid].status != staffed "Staffed worker $wid found in broker pool"
    end

    # Finite satisfaction
    for firm in state.firms
        @assert isfinite(firm.satisfaction_internal) "NaN/Inf satisfaction_internal at firm $(firm.id)"
        @assert isfinite(firm.satisfaction_broker) "NaN/Inf satisfaction_broker at firm $(firm.id)"
    end

    # Reservation wage floor
    for w in state.workers
        @assert w.reservation_wage >= state.cal.r_base "Worker $(w.id) reservation wage $(w.reservation_wage) < r_base $(state.cal.r_base)"
    end

    return nothing
end
