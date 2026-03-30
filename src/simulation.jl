"""
    simulation.jl

Simulation runner and per-period metric collection.
"""

"""Mean of a vector, or NaN if empty."""
safe_mean(v::Vector{Float64}) = isempty(v) ? NaN : mean(v)

"""
    RollingPairs(window)

Accumulates prediction/outcome pairs across periods, keeping the last `window`
periods of pairs for rolling R-squared computation.
"""
mutable struct RollingPairs
    predicted::Vector{Vector{Float64}}  # ring buffer of per-period vectors
    realized::Vector{Vector{Float64}}
    window::Int
    pos::Int  # next write position (1-indexed, wraps)
    count::Int  # total periods written
end

function RollingPairs(window::Int)
    RollingPairs([Float64[] for _ in 1:window],
                 [Float64[] for _ in 1:window],
                 window, 1, 0)
end

"""Push one period's pairs into the ring buffer."""
function push_period!(rp::RollingPairs, pred::Vector{Float64}, real::Vector{Float64})
    rp.predicted[rp.pos] = copy(pred)
    rp.realized[rp.pos] = copy(real)
    rp.pos = mod1(rp.pos + 1, rp.window)
    rp.count += 1
    return nothing
end

"""Concatenate all pairs in the window and compute prediction quality."""
function rolling_prediction_quality(rp::RollingPairs)::PredictionQuality
    n_slots = min(rp.count, rp.window)
    pred = reduce(vcat, rp.predicted[1:n_slots])
    real = reduce(vcat, rp.realized[1:n_slots])
    return compute_prediction_quality(pred, real)
end

"""
    collect_period_metrics(state, firm_rolling, broker_rolling, firm_holdout_rolling, broker_holdout_rolling) -> NamedTuple

Extract one row of metrics from the current state after `step_period!`.
Selected-sample metrics reflect prediction quality on actual matches (subject to winner's curse).
Holdout metrics reflect model quality on random workers with noiseless truth (no selection bias).
"""
function collect_period_metrics(state::ModelState,
                                firm_rolling::RollingPairs,
                                broker_rolling::RollingPairs,
                                firm_holdout_rolling::RollingPairs,
                                broker_holdout_rolling::RollingPairs)
    a = state.accum
    b = state.broker
    cn = state.cached_network

    # Selected-sample rolling metrics
    push_period!(firm_rolling, a.firm_predicted, a.firm_realized)
    push_period!(broker_rolling, a.broker_predicted, a.broker_realized)
    firm_rpq = rolling_prediction_quality(firm_rolling)
    broker_rpq = rolling_prediction_quality(broker_rolling)

    # Holdout rolling metrics
    push_period!(firm_holdout_rolling, a.firm_holdout_pred, a.firm_holdout_real)
    push_period!(broker_holdout_rolling, a.broker_holdout_pred, a.broker_holdout_real)
    firm_hpq = rolling_prediction_quality(firm_holdout_rolling)
    broker_hpq = rolling_prediction_quality(broker_holdout_rolling)

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
        firm_r_squared_rolling = firm_rpq.r_squared,
        broker_r_squared_rolling = broker_rpq.r_squared,
        firm_bias_rolling = firm_rpq.bias,
        broker_bias_rolling = broker_rpq.bias,
        firm_rank_corr_rolling = firm_rpq.rank_corr,
        broker_rank_corr_rolling = broker_rpq.rank_corr,
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
    )
end

"""
    run_simulation(params; verify=false, r_squared_window=5) -> (ModelState, DataFrame)

Initialize the model and run for T periods, collecting per-period metrics.
Prediction quality (R-squared, bias, rank correlation) is computed over a rolling
window of `r_squared_window` periods. When `verify=true`, calls `verify_invariants` each period.
"""
function run_simulation(params::ModelParams; verify::Bool = false,
                        r_squared_window::Int = 5)
    if Threads.nthreads() == 1
        @warn "Running single-threaded; start Julia with --threads=auto for faster betweenness computation"
    end
    state = initialize_model(params)
    T = params.T

    firm_rolling = RollingPairs(r_squared_window)
    broker_rolling = RollingPairs(r_squared_window)
    firm_holdout_rolling = RollingPairs(r_squared_window)
    broker_holdout_rolling = RollingPairs(r_squared_window)

    step_period!(state)
    verify && verify_invariants(state)
    first_row = collect_period_metrics(state, firm_rolling, broker_rolling,
                                       firm_holdout_rolling, broker_holdout_rolling)
    rows = Vector{typeof(first_row)}(undef, T)
    rows[1] = first_row

    for t in 2:T
        step_period!(state)
        verify && verify_invariants(state)
        rows[t] = collect_period_metrics(state, firm_rolling, broker_rolling,
                                          firm_holdout_rolling, broker_holdout_rolling)
    end

    mdf = DataFrame(rows)
    return (state, mdf)
end
