"""
    entry_exit.jl

Firm entry and exit (§4, §8 step 5). Worker population is fixed.
"""

"""
    exit_firm!(state, firm_idx, avail)

Vacate a firm slot: release employees to available, clear from open_vacancies.
The firm struct remains at `firm_idx` until `enter_firm!` replaces it.
Workers retain their positions in G_S and broker pool.
"""
function exit_firm!(state::ModelState, firm_idx::Int, avail::Set{Int})
    firm = state.firms[firm_idx]
    for wid in firm.employees
        state.workers[wid].status = available
        state.workers[wid].employer_id = 0
        push!(avail, wid)
    end
    empty!(firm.employees)
    delete!(state.open_vacancies, firm_idx)
    # Terminate active staffing assignments at this firm (§9g step 5.1)
    if state.params.enable_staffing
        terminate_firm_assignments!(state, firm_idx, avail)
    end
    return nothing
end

"""
    enter_firm!(state, firm_idx, avail, candidates, wts)

Reset the firm at `firm_idx` in-place as a fresh entrant: new type, cleared history,
satisfaction at q_pub, and 6-10 employees drawn by type proximity from `avail`.
Reuses existing history buffers to avoid allocation. `candidates` and `wts` are
pre-allocated buffers.
"""
function enter_firm!(state::ModelState, firm_idx::Int, avail::Set{Int},
                     candidates::Vector{Int}, wts::Vector{Float64})
    rng = state.rng
    q_pub = state.cal.q_pub

    firm = state.firms[firm_idx]
    new_type = sample_firm_type(state.firm_geo, rand(rng), state.params.d, rng)

    # Reset firm in-place, reusing history buffers
    firm.id = state.next_firm_id
    state.next_firm_id += 1
    firm.type .= new_type
    empty!(firm.employees)
    firm.history_count = 0
    firm.satisfaction_internal = q_pub
    firm.satisfaction_broker = q_pub
    firm.tried_internal = false
    firm.tried_broker = false
    empty!(firm.referral_pool)
    firm.hire_count = 0
    firm.periods_alive = 0

    n_initial = rand(rng, 6:10)
    nc = length(avail)
    n_hire = min(n_initial, nc)
    if n_hire > 0
        resize!(candidates, nc)
        copyto!(candidates, avail)
        chosen = sample_by_proximity(rng, candidates, nc, state.workers,
                                      firm.type, wts, n_hire)
        for wid in chosen
            state.workers[wid].status = employed
            state.workers[wid].employer_id = firm.id
            push!(firm.employees, wid)
            delete!(avail, wid)
            q = match_output(state.workers[wid].type, firm.type, state.env, rng)
            record_history!(firm, state.workers[wid].type, q)
        end
    end

    return nothing
end

"""
    process_entry_exit!(state, avail)

Each firm exits with probability eta and is immediately replaced by an entrant (§8 step 5).
`avail` is the shared available set from the step loop, updated in place.
"""
function process_entry_exit!(state::ModelState, avail::Set{Int})
    rng = state.rng
    eta = state.params.eta
    candidates = Vector{Int}(undef, length(avail))
    wts = Vector{Float64}(undef, length(avail))
    for j in eachindex(state.firms)
        if rand(rng) < eta
            exit_firm!(state, j, avail)
            enter_firm!(state, j, avail, candidates, wts)
        end
    end
    return nothing
end
