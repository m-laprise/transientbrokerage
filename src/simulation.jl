"""
    simulation.jl

Simulation runner and per-period metric collection.
"""

"""Mean of a vector, or NaN if empty."""
safe_mean(v::Vector{Float64}) = isempty(v) ? NaN : mean(v)

"""
    collect_period_metrics(state) -> NamedTuple

Extract one row of metrics from the current state after `step_period!`.
Prediction quality computed directly from this period's pairs (no rolling window).
Selected-sample metrics reflect prediction quality on actual matches (subject to winner's curse).
Holdout metrics reflect model quality on random workers with noiseless truth (no selection bias).
"""
function collect_period_metrics(state::ModelState)
    a = state.accum
    b = state.broker
    cn = state.cached_network

    # Per-period prediction quality (selected sample — actual hires)
    firm_rpq = compute_prediction_quality(a.firm_predicted, a.firm_realized)
    broker_rpq = compute_prediction_quality(a.broker_predicted, a.broker_realized)

    # Per-period holdout quality (random workers at random firms, noiseless truth)
    firm_hpq = compute_prediction_quality(a.firm_holdout_pred, a.firm_holdout_real)
    broker_hpq = compute_prediction_quality(a.broker_holdout_pred, a.broker_holdout_real)

    return (
        period = state.period,
        matches = a.matches,
        outsourcing_rate = a.outsourcing_rate,
        openings_internal = a.openings_internal,
        openings_brokered = a.openings_brokered,
        vacancies_internal = a.vacancies_internal,
        vacancies_brokered = a.vacancies_brokered,
        q_direct_mean = safe_mean(a.q_direct),
        q_placed_mean = safe_mean(a.q_placed),
        n_direct = length(a.q_direct),
        n_placed = length(a.q_placed),
        broker_history_size = effective_history_size(b),
        broker_pool_size = length(b.pool),
        broker_reputation = b.last_reputation,
        betweenness = cn.betweenness,
        constraint = cn.constraint,
        effective_size = cn.effective_size,
        placement_revenue = a.placement_revenue,
        cumulative_placement_revenue = a.cumulative_placement_revenue,
        access_count = a.access_count,
        assessment_count = a.assessment_count,
        # Selected-sample metrics (actual matches, subject to winner's curse)
        firm_r_squared_selected = firm_rpq.r_squared,
        broker_r_squared_selected = broker_rpq.r_squared,
        firm_bias_selected = firm_rpq.bias,
        broker_bias_selected = broker_rpq.bias,
        firm_rank_corr_selected = firm_rpq.rank_corr,
        broker_rank_corr_selected = broker_rpq.rank_corr,
        # Holdout metrics (random workers, noiseless truth, no selection bias)
        firm_r_squared_holdout = firm_hpq.r_squared,
        broker_r_squared_holdout = broker_hpq.r_squared,
        firm_bias_holdout = firm_hpq.bias,
        broker_bias_holdout = broker_hpq.bias,
        firm_rank_corr_holdout = firm_hpq.rank_corr,
        broker_rank_corr_holdout = broker_hpq.rank_corr,
        # Broker-firm gaps (broker minus firm; positive = broker advantage)
        gap_r_squared_holdout = broker_hpq.r_squared - firm_hpq.r_squared,
        gap_rank_corr_selected = broker_rpq.rank_corr - firm_rpq.rank_corr,
        gap_r_squared_selected = broker_rpq.r_squared - firm_rpq.r_squared,
        # Market state
        n_available = count(w -> w.status == available, state.workers),
        avg_firm_size = mean(length(f.employees) for f in state.firms),
        avg_referral_pool_size = mean(length(f.referral_pool) for f in state.firms),
        n_broker_clients = length(state.broker_clients),
        # Surplus apportionment (§8 step 7.3)
        total_realized_surplus = a.total_realized_surplus,
        worker_surplus = a.worker_surplus,
        firm_surplus_direct = a.firm_surplus_direct,
        firm_surplus_placed = a.firm_surplus_placed,
        firm_surplus_staffed = a.firm_surplus_staffed,
        broker_surplus_placement = a.broker_surplus_placement,
        broker_surplus_staffing = a.broker_surplus_staffing,
        n_active_staffing = a.n_active_staffing,
        # Staffing metrics (Model 1; zero when enable_staffing=false)
        n_staffing_new = a.new_staffing,
        n_staffed = length(a.q_staffed),
        q_staffed_mean = safe_mean(a.q_staffed),
        staffing_revenue = a.staffing_revenue,
        cumulative_staffing_revenue = a.cumulative_staffing_revenue,
        flow_capture_rate = let np = a.new_placements; ns = a.new_staffing
            (np + ns) > 0 ? ns / (np + ns) : NaN
        end,
    )
end

"""
    run_simulation(params; verify=false) -> (ModelState, DataFrame)

Initialize the model and run for T periods, collecting per-period metrics.
When `verify=true`, calls `verify_invariants` each period.
"""
function run_simulation(params::ModelParams; verify::Bool = false)
    if Threads.nthreads() == 1
        @warn "Running single-threaded; start Julia with --threads=auto for faster betweenness computation"
    end
    state = initialize_model(params)
    T = params.T

    step_period!(state)
    verify && verify_invariants(state)
    first_row = collect_period_metrics(state)
    rows = Vector{typeof(first_row)}(undef, T)
    rows[1] = first_row

    for t in 2:T
        step_period!(state)
        verify && verify_invariants(state)
        rows[t] = collect_period_metrics(state)
    end

    mdf = DataFrame(rows)
    return (state, mdf)
end
