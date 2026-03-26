"""
    step.jl

Main simulation loop: one period of the model (§8 steps 0-7).
"""

"""
    step_period!(state)

Execute one period of the simulation. Steps:
0. Referral pools
1. Vacancy management and outsourcing decisions
2. Candidate generation and evaluation (internal search + broker allocation)
3. Match formation (wage setting, conflict resolution, finalization)
4. Reputation update
5. Entry/exit
6. Broker pool maintenance (remove non-available, top up to target P)
7. Network measures (every M periods)
"""
function step_period!(state::ModelState)
    state.period += 1
    params = state.params
    rng = state.rng
    reset_accumulators!(state.accum)

    avail = Set(w.id for w in state.workers if w.status == available)

    # ── Step 0: Referral pools ──
    compute_all_referral_pools!(state.firms, state.workers, state.G_S)

    # ── Step 1: Vacancy management and outsourcing decisions ──
    # 1.1 Carry forward unfilled vacancies (already in state.open_vacancies)
    # 1.2 New vacancies for firms without one
    for j in eachindex(state.firms)
        if j ∉ state.open_vacancies && rand(rng) < params.p_vac
            push!(state.open_vacancies, j)
        end
    end

    # 1.3-1.4 Outsourcing decisions
    # Reputation uses previous period's cached value (broker.last_reputation),
    # so all firms see the same reputation regardless of iteration order.
    current_broker_firms = Set{Int}()
    decisions = Dict{Int, Symbol}()
    for j in state.open_vacancies
        dec = outsourcing_decision(state.firms[j], state.broker,
                                    state.cal.q_pub, rng)
        decisions[j] = dec
        if dec == :internal
            state.accum.openings_internal += 1
        else
            state.accum.openings_brokered += 1
            push!(current_broker_firms, j)
        end
    end

    # Outsourcing rate = |J^t| / |V^t|
    n_vacancies = length(state.open_vacancies)
    state.accum.outsourcing_rate = n_vacancies > 0 ?
        length(current_broker_firms) / n_vacancies : 0.0

    # ── Step 2: Candidate generation and evaluation ──
    client_firm_indices = collect(current_broker_firms)
    trees = build_period_trees(state, client_firm_indices)
    cache = PredictionCache(params.k_nn)
    s_dim = size(state.env.P, 1)
    z_buf = Vector{Float64}(undef, s_dim)
    Ax_buf = Vector{Float64}(undef, params.d)

    proposals = ProposedMatch[]

    # 2.1 Internal searches
    for (j, dec) in decisions
        dec == :internal || continue
        firm = state.firms[j]
        wid, q_hat_firm = internal_search(firm, state.workers, avail,
                                           state.accum, params, state.cal.q_pub,
                                           rng, trees.firm_trees[j], cache)
        wid == 0 && continue
        wage = compute_wage(q_hat_firm, state.workers[wid].reservation_wage, params.beta_W)
        push!(proposals, ProposedMatch(j, wid, :internal, q_hat_firm, 0.0, wage))
    end

    # 2.2 Broker proposals (greedy best-pair)
    clients = [(j, state.firms[j]) for j in client_firm_indices]
    assignments = broker_allocate!(state.broker, clients, state.workers, avail,
                                    state.accum, params, state.cal.q_pub,
                                    rng, trees, cache)

    served_firms = Set{Int}()
    for (j, wid, q_hat_broker) in assignments
        # Firm re-evaluates candidate for wage setting (§3.1.1)
        q_hat_firm = predict_firm(state.firms[j], state.workers[wid].type,
                                   state.cal.q_pub, params.k_nn,
                                   trees.firm_trees[j], cache).q_hat
        wage = compute_wage(q_hat_firm, state.workers[wid].reservation_wage, params.beta_W)
        push!(proposals, ProposedMatch(j, wid, :broker, q_hat_firm, q_hat_broker, wage))
        push!(served_firms, j)
    end

    # No-proposal penalty for unserved broker clients
    for j in client_firm_indices
        if j ∉ served_firms
            penalize_no_proposal!(state.firms[j], params.omega)
        end
    end

    # ── Step 3: Match formation ──
    accepted = resolve_conflicts(proposals, rng)

    filled_firms = Set{Int}()
    for match in accepted
        q = finalize_match!(match, state, z_buf, Ax_buf)

        # Record output by channel
        if match.source == :internal
            push!(state.accum.q_direct, q)
        else
            push!(state.accum.q_placed, q)
            state.accum.new_placements += 1
            state.accum.placement_revenue += params.alpha * match.wage
            state.accum.cumulative_placement_revenue += params.alpha * match.wage
        end

        # Prediction/outcome pairs for R-squared
        push!(state.accum.firm_predicted, match.q_hat_firm)
        push!(state.accum.firm_realized, q)
        if match.source == :broker
            push!(state.accum.broker_predicted, match.q_hat_broker)
            push!(state.accum.broker_realized, q)
        end

        # Access vs assessment classification
        in_ref = match.source == :broker &&
                 match.worker_id in state.firms[match.firm_idx].referral_pool
        record_match!(state.accum, match.source, in_ref)
        push!(filled_firms, match.firm_idx)
    end

    # Close filled vacancies, count unfilled
    for (j, dec) in decisions
        if j in filled_firms
            delete!(state.open_vacancies, j)
        else
            if dec == :internal
                state.accum.vacancies_internal += 1
            else
                state.accum.vacancies_brokered += 1
            end
        end
    end

    # ── Step 4: Reputation update ──
    update_broker_reputation!(state.broker, state.firms, current_broker_firms)

    # ── Step 5: Entry/exit ──
    # Rebuild avail (matching may have changed it)
    empty!(avail)
    for w in state.workers
        w.status == available && push!(avail, w.id)
    end
    process_entry_exit!(state, avail)

    # ── Step 6: Broker pool maintenance ──
    # Remove non-available workers, top up to target P.
    # Runs after entry/exit so workers hired by entrant firms are also removed.
    pool = state.broker.pool
    for wid in collect(pool)
        state.workers[wid].status == available || delete!(pool, wid)
    end
    P = ceil(Int, params.pool_target_frac * params.N_W)
    n_gap = P - length(pool)
    if n_gap > 0
        eligible = Int[]
        for w in state.workers
            if w.status == available && w.id ∉ pool
                push!(eligible, w.id)
            end
        end
        if !isempty(eligible)
            n_draw = min(n_gap, length(eligible))
            recruited = sample(rng, eligible, n_draw; replace=false)
            for wid in recruited
                push!(pool, wid)
            end
        end
    end

    # ── Step 7: Network measures (every M periods) ──
    if state.period % params.network_measure_interval == 0
        update_cached_network_measures!(state)
    end

    return nothing
end
