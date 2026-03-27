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
    return nothing
end

"""
    enter_firm!(state, firm_idx, avail, candidates, wts)

Replace the firm at `firm_idx` with a fresh entrant: new type, empty history,
satisfaction at q_pub, and 3-5 employees drawn by type proximity from `avail`.
`candidates` and `wts` are pre-allocated buffers.
"""
function enter_firm!(state::ModelState, firm_idx::Int, avail::Set{Int},
                     candidates::Vector{Int}, wts::Vector{Float64})
    rng = state.rng
    q_pub = state.cal.q_pub

    new_type = sample_firm_type(state.firm_curve, rand(rng), state.params.d, rng)
    new_firm = create_firm(state.next_firm_id, new_type, state.params.d)
    state.next_firm_id += 1
    new_firm.satisfaction_internal = q_pub
    new_firm.satisfaction_broker = q_pub

    n_initial = rand(rng, 3:5)
    nc = length(avail)
    n_hire = min(n_initial, nc)
    if n_hire > 0
        resize!(candidates, nc)
        copyto!(candidates, avail)
        chosen = sample_by_proximity(rng, candidates, nc, state.workers,
                                      new_firm.type, wts, n_hire)
        for wid in chosen
            state.workers[wid].status = employed
            state.workers[wid].employer_id = new_firm.id
            push!(new_firm.employees, wid)
            delete!(avail, wid)
        end
    end

    state.firms[firm_idx] = new_firm
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
