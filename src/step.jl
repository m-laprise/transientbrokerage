"""
    step.jl

Main simulation loop: one period of the model (§8 steps 0-7).
"""

"""
    step_period!(state)

Execute one period of the simulation. Steps:
0. Broker pool maintenance (purge non-available, refill to target P)
1. Referral pool computation
2. Vacancy management (dual-vacancy draw) and outsourcing decisions
3. Candidate generation and evaluation (internal search + broker allocation)
4. Match formation (wage setting, conflict resolution, finalization with coworker ties)
   4b. Staffing economics for active assignments (Model 1)
   Holdout prediction evaluation
5. Broker reputation update, pool purge
6. Entry/exit (firm turnover with replacement)
7. Network measures (every M periods)
"""
function step_period!(state::ModelState)
    state.period += 1
    params = state.params
    rng = state.rng
    reset_accumulators!(state.accum)
    n_holdout = 100
    sizehint!(state.accum.firm_holdout_pred, n_holdout)
    sizehint!(state.accum.firm_holdout_real, n_holdout)
    sizehint!(state.accum.broker_holdout_pred, n_holdout)
    sizehint!(state.accum.broker_holdout_real, n_holdout)

    N_W = length(state.workers)

    # ── Step 0: Broker pool maintenance ──
    # Purge non-available workers, top up to target P before candidate generation.
    # Runs before matching so newly available workers (from previous period's
    # entry/exit) can be recruited into the pool and proposed by the broker.
    # Replenishment is half referral (G_S neighbors of pool) and half random,
    # sampling directly from eligible workers (no rejection sampling).
    pool = state.broker.pool
    for wid in collect(pool)
        state.workers[wid].status == available || delete!(pool, wid)
    end
    P = ceil(Int, params.pool_target_frac * params.N_W)
    n_gap = P - length(pool)
    if n_gap > 0
        # Build eligible set: available workers not already in pool
        eligible = Int[]
        for w in state.workers
            w.status == available && w.id ∉ pool && push!(eligible, w.id)
        end

        if !isempty(eligible)
            n_to_add = min(n_gap, length(eligible))

            # Referral half: G_S neighbors of current pool members
            n_referral_target = isempty(pool) ? 0 : n_to_add ÷ 2
            n_added_ref = 0
            if n_referral_target > 0
                referral_eligible = Int[]
                pool_set = pool  # Set lookup for neighbor filtering
                for wid in eligible
                    for nbr in neighbors(state.G_S, wid)
                        if nbr in pool_set
                            push!(referral_eligible, wid)
                            break
                        end
                    end
                end
                if !isempty(referral_eligible)
                    n_ref = min(n_referral_target, length(referral_eligible))
                    ref_sample = sample(rng, referral_eligible, n_ref; replace=false)
                    for wid in ref_sample
                        push!(pool, wid)
                        n_added_ref += 1
                    end
                end
            end

            # General half (+ unfilled referral slots): random from remaining eligible
            n_general = n_to_add - n_added_ref
            if n_general > 0
                general_eligible = filter(wid -> wid ∉ pool, eligible)
                n_gen = min(n_general, length(general_eligible))
                if n_gen > 0
                    gen_sample = sample(rng, general_eligible, n_gen; replace=false)
                    for wid in gen_sample
                        push!(pool, wid)
                    end
                end
            end
        end
    end

    state.accum.broker_pool_size_post_maintenance = length(pool)

    # Build available BitVector (after pool maintenance, for candidate generation)
    avail = falses(N_W)
    for w in state.workers
        w.status == available && (avail[w.id] = true)
    end

    # ── Step 1: Referral pools ──
    compute_all_referral_pools!(state.firms, state.workers, state.G_S)

    # ── Step 2: Vacancy management and outsourcing decisions ──
    # 1.1 Carry forward unfilled vacancies (already in state.open_vacancies)
    # 1.2 New vacancies: firms without open vacancies draw with prob p_vac;
    #     conditional on drawing, 50/50 chance of 1 or 2 vacancies (max 2).
    for j in eachindex(state.firms)
        state.open_vacancies[j] > 0 && continue
        if rand(rng) < params.p_vac
            state.open_vacancies[j] = rand(rng) < 0.5 ? 2 : 1
        end
    end

    # 1.3-1.4 Outsourcing decisions (one per firm, applied to all its vacancies)
    # Reputation uses previous period's cached value (broker.last_reputation),
    # so all firms see the same reputation regardless of iteration order.
    empty!(state.broker_clients)
    current_broker_firms = state.broker_clients
    decisions = Dict{Int, Symbol}()
    for j in eachindex(state.open_vacancies)
        n_vac = state.open_vacancies[j]
        n_vac == 0 && continue
        dec = outsourcing_decision(state.firms[j], state.broker,
                                    state.cal.q_pub, rng)
        decisions[j] = dec
        state.firms[j].last_channel = dec
        if dec == :internal
            state.accum.openings_internal += n_vac
        else
            state.accum.openings_brokered += n_vac
            push!(current_broker_firms, j)
        end
    end

    # Outsourcing rate = fraction of firms with vacancies choosing broker
    n_firms_with_vac = length(decisions)
    state.accum.outsourcing_rate = n_firms_with_vac > 0 ?
        length(current_broker_firms) / n_firms_with_vac : 0.0

    # ── Step 3: Candidate generation and evaluation ──
    models = build_period_models(state, params.lambda)

    d = params.d
    N_F = length(state.firms)
    firm_buf = Vector{Float64}(undef, 2d)
    broker_buf = Vector{Float64}(undef, broker_feature_dim(d))
    Ax_buf = Vector{Float64}(undef, d)

    proposals = ProposedMatch[]

    # 2.1 Internal searches (one search per vacancy; guard against duplicate worker)
    for (j, dec) in decisions
        dec == :internal || continue
        firm = state.firms[j]
        n_vac = state.open_vacancies[j]
        first_wid = 0
        for v in 1:n_vac
            wid, q_hat_firm = internal_search(firm, state.workers, avail,
                                               params, rng, models.firm_models[j])
            (wid == 0 || wid == first_wid) && continue
            wage = compute_wage(q_hat_firm, state.workers[wid].reservation_wage, params.beta_W)
            push!(proposals, ProposedMatch(j, wid, :internal, q_hat_firm, 0.0, wage))
            v == 1 && (first_wid = wid)
        end
    end

    # 2.2 Broker proposals (greedy best-pair; firms with 2 vacancies appear twice)
    client_firm_indices = Int[]
    for j in current_broker_firms
        for _ in 1:state.open_vacancies[j]
            push!(client_firm_indices, j)
        end
    end
    clients = [(j, state.firms[j]) for j in client_firm_indices]
    assignments = broker_allocate!(state.broker, clients, state.workers, avail,
                                    params, rng, models)

    served_firms = Set{Int}()
    for (j, wid, q_hat_broker) in assignments
        # Firm re-evaluates candidate for wage setting (§3.1.1)
        q_hat_firm = predict_ridge!(models.firm_models[j], firm_buf, state.workers[wid].type)
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

    # ── Step 4: Match formation ──
    accepted = resolve_conflicts(proposals, rng)

    filled_count = Dict{Int, Int}()
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
        filled_count[match.firm_idx] = get(filled_count, match.firm_idx, 0) + 1
    end

    # Close filled vacancies, count unfilled
    for (j, dec) in decisions
        n_vac = state.open_vacancies[j]
        n_filled = get(filled_count, j, 0)
        n_unfilled = n_vac - n_filled
        state.open_vacancies[j] = max(n_unfilled, 0)
        if n_unfilled > 0
            if dec == :internal
                state.accum.vacancies_internal += n_unfilled
            else
                state.accum.vacancies_brokered += n_unfilled
            end
        end
    end

    # ── Holdout evaluation (after matching, so we know if broker made matches) ──
    # Firm holdout always computed; broker holdout only when broker placed or staffed
    broker_matched = length(state.accum.q_placed) + state.accum.new_staffing > 0
    for _ in 1:n_holdout
        wid = rand(rng, 1:N_W)
        j = rand(rng, 1:N_F)
        w = state.workers[wid].type
        x = state.firms[j].type
        q_true = Q_OFFSET + match_signal!(Ax_buf, w, x, state.env)
        push!(state.accum.firm_holdout_pred, predict_ridge!(models.firm_models[j], firm_buf, w))
        push!(state.accum.firm_holdout_real, q_true)
        if broker_matched
            push!(state.accum.broker_holdout_pred, predict_ridge!(models.broker_model, broker_buf, w, x))
            push!(state.accum.broker_holdout_real, q_true)
        end
    end

    # ── Step 4b: Staffing economics for active assignments ──
    if params.enable_staffing
        process_staffing_economics!(state)
    end

    # ── Step 5: Reputation update ──
    # Include firms with active staffing assignments as broker clients (§9g step 4.3)
    if params.enable_staffing
        for a in state.broker.active_assignments
            push!(current_broker_firms, a.firm_idx)
        end
    end
    update_broker_reputation!(state.broker, state.firms, current_broker_firms)

    # ── Step 6: Entry/exit ──
    # Rebuild avail (matching may have changed it)
    fill!(avail, false)
    for w in state.workers
        w.status == available && (avail[w.id] = true)
    end
    process_entry_exit!(state, avail)

    # Purge non-available workers from pool (hired during matching or entry/exit)
    for wid in collect(state.broker.pool)
        state.workers[wid].status == available || delete!(state.broker.pool, wid)
    end

    # ── Step 7: Network measures (every M periods) ──
    if state.period % params.network_measure_interval == 0
        update_cached_network_measures!(state)
    end

    return nothing
end
