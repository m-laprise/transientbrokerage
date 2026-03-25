"""
    invariants.jl

Debug-time state consistency checks. Disable in production runs for performance.
"""

"""
    verify_invariants!(state)

Assert that the simulation state is internally consistent. Checks worker
conservation, no double-employment, status consistency, finite satisfaction,
and reservation wage floor. Intended for use in test runs; disable in production.
"""
function verify_invariants!(state::ModelState)
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

    # Open vacancies in bounds
    for j in state.open_vacancies
        @assert 1 <= j <= length(state.firms) "Open vacancy index $j out of bounds"
    end

    # Broker pool non-empty after first period
    if state.period > 1
        @assert !isempty(state.broker.pool) "Broker pool empty after period 1"
    end

    # Staffing assignment consistency
    for assignment in state.broker.active_assignments
        w = state.workers[assignment.worker_id]
        @assert w.status == staffed "Staffed worker $(assignment.worker_id) has status=$(w.status)"
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
