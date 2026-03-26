"""
    simulation.jl

Simulation runner and per-period metric collection.
"""

"""
    safe_mean(v) -> Float64

Mean of a vector, or NaN if empty.
"""
safe_mean(v::Vector{Float64}) = isempty(v) ? NaN : mean(v)

"""
    collect_period_metrics(state) -> NamedTuple

Extract one row of metrics from the current state after `step_period!`.
"""
function collect_period_metrics(state::ModelState)
    a = state.accum
    b = state.broker
    cn = state.cached_network

    # Per-period R-squared from prediction/outcome pairs
    firm_pq = compute_prediction_quality(a.firm_predicted, a.firm_realized)
    broker_pq = compute_prediction_quality(a.broker_predicted, a.broker_realized)

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
        firm_r_squared = firm_pq.r_squared,
        broker_r_squared = broker_pq.r_squared,
    )
end

"""
    run_simulation(params; verify=false) -> (ModelState, DataFrame)

Initialize the model and run for T periods, collecting per-period metrics.
When `verify=true`, calls `verify_invariants!` each period.
"""
function run_simulation(params::ModelParams; verify::Bool = false)
    state = initialize_model(params)
    T = params.T

    # First period to infer row type
    step_period!(state)
    verify && verify_invariants!(state)
    first_row = collect_period_metrics(state)
    rows = Vector{typeof(first_row)}(undef, T)
    rows[1] = first_row

    for t in 2:T
        step_period!(state)
        verify && verify_invariants!(state)
        rows[t] = collect_period_metrics(state)
    end

    mdf = DataFrame(rows)
    return (state, mdf)
end
