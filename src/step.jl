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
    empty!(state.broker_clients)
    current_broker_firms = state.broker_clients
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
    models = build_period_models(state, params.lambda)

    # Holdout evaluation: sample actual workers at random firms, noiseless truth (no selection bias)
    # Uses existing workers (not synthetic), evaluated at random firms they may or may not be near.
    d = params.d
    firm_buf = Vector{Float64}(undef, 2d)
    broker_buf = Vector{Float64}(undef, broker_feature_dim(d))
    Ax_buf = Vector{Float64}(undef, d)
    N_W = length(state.workers)
    N_F = length(state.firms)
    for _ in 1:(3 * N_F)
        wid = rand(rng, 1:N_W)
        j = rand(rng, 1:N_F)
        w = state.workers[wid].type
        x = state.firms[j].type
        q_true = Q_OFFSET + match_output_noiseless!(Ax_buf, w, x, state.env)
        push!(state.accum.firm_holdout_pred, predict_ridge!(models.firm_models[j], firm_buf, w))
        push!(state.accum.firm_holdout_real, q_true)
        push!(state.accum.broker_holdout_pred, predict_ridge!(models.broker_model, broker_buf, w, x))
        push!(state.accum.broker_holdout_real, q_true)
    end

    proposals = ProposedMatch[]

    # 2.1 Internal searches
    for (j, dec) in decisions
        dec == :internal || continue
        firm = state.firms[j]
        wid, q_hat_firm = internal_search(firm, state.workers, avail,
                                           params, rng, models.firm_models[j])
        wid == 0 && continue
        wage = compute_wage(q_hat_firm, state.workers[wid].reservation_wage, params.beta_W)
        push!(proposals, ProposedMatch(j, wid, :internal, q_hat_firm, 0.0, wage))
    end

    # 2.2 Broker proposals (greedy best-pair)
    client_firm_indices = collect(current_broker_firms)
    clients = [(j, state.firms[j]) for j in client_firm_indices]
    assignments = broker_allocate!(state.broker, clients, state.workers, avail,
                                    params, rng, models)

    served_firms = Set{Int}()
    for (j, wid, q_hat_broker) in assignments
        # Firm re-evaluates candidate for wage setting (§3.1.1)
        q_hat_firm = predict_ridge(models.firm_models[j], firm_features(state.workers[wid].type))
        r_i = state.workers[wid].reservation_wage

        # Staffing decision (§9d, §9e): broker decides, then firm accepts/rejects
        if params.enable_staffing &&
           broker_prefers_staffing(q_hat_broker, r_i, params, state.cal.r_base) &&
           firm_accepts_staffing(q_hat_broker, q_hat_firm, r_i, params)
            # Staffing: wage = r_i (§9b); loses to internal offers in conflict resolution
            push!(proposals, ProposedMatch(j, wid, :staffing, q_hat_firm, q_hat_broker, r_i))
        else
            # Placement: normal wage
            wage = compute_wage(q_hat_firm, r_i, params.beta_W)
            push!(proposals, ProposedMatch(j, wid, :broker, q_hat_firm, q_hat_broker, wage))
        end
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
        if match.source == :staffing
            q = create_staffing_assignment!(state, match, match.q_hat_broker)
            push!(state.accum.q_staffed, q)
            state.accum.new_staffing += 1
            # Broker prediction/outcome pair (staffing uses broker's prediction)
            push!(state.accum.broker_predicted, match.q_hat_broker)
            push!(state.accum.broker_realized, q)
            # Access vs assessment: staffing counts as brokered
            in_ref = match.worker_id in state.firms[match.firm_idx].referral_pool
            record_match!(state.accum, :broker, in_ref)
        else
            q = finalize_match!(match, state)
            if match.source == :internal
                push!(state.accum.q_direct, q)
            else  # :broker placement
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
        end
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

    # ── Step 3b: Staffing economics for active assignments ──
    if params.enable_staffing
        process_staffing_economics!(state)
    end

    # ── Step 4: Reputation update ──
    # Include firms with active staffing assignments as broker clients (§9g step 4.3)
    if params.enable_staffing
        for a in state.broker.active_assignments
            push!(current_broker_firms, a.firm_idx)
        end
    end
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
    # Replenishment is half referral (G_S neighbors of current pool) and half random,
    # mirroring firms' 50/50 referral/general candidate sourcing (§5a).
    # Runs after entry/exit so workers hired by entrant firms are also removed.
    pool = state.broker.pool
    for wid in collect(pool)
        state.workers[wid].status == available || delete!(pool, wid)
    end
    P = ceil(Int, params.pool_target_frac * params.N_W)
    n_gap = P - length(pool)
    if n_gap > 0
        # Partition eligible workers into referral (G_S neighbors of pool) and general
        referral_eligible = Int[]
        general_eligible = Int[]
        pool_neighbor_set = Set{Int}()
        for wid in pool
            for nbr in neighbors(state.G_S, wid)
                push!(pool_neighbor_set, nbr)
            end
        end
        for w in state.workers
            if w.status == available && w.id ∉ pool
                if w.id in pool_neighbor_set
                    push!(referral_eligible, w.id)
                else
                    push!(general_eligible, w.id)
                end
            end
        end
        # Draw half from referral, remainder from general
        half_gap = n_gap ÷ 2
        n_referral = min(half_gap, length(referral_eligible))
        n_general = min(n_gap - n_referral, length(general_eligible))
        # If one source is exhausted, draw remaining from the other
        n_remaining = n_gap - n_referral - n_general
        if n_remaining > 0
            n_extra_ref = min(n_remaining, length(referral_eligible) - n_referral)
            n_referral += n_extra_ref
            n_remaining -= n_extra_ref
            n_extra_gen = min(n_remaining, length(general_eligible) - n_general)
            n_general += n_extra_gen
        end
        if n_referral > 0
            recruited = sample(rng, referral_eligible, n_referral; replace=false)
            for wid in recruited; push!(pool, wid); end
        end
        if n_general > 0
            recruited = sample(rng, general_eligible, n_general; replace=false)
            for wid in recruited; push!(pool, wid); end
        end
    end

    # ── Step 7: Network measures (every M periods) ──
    if state.period % params.network_measure_interval == 0
        update_cached_network_measures!(state)
    end

    return nothing
end
