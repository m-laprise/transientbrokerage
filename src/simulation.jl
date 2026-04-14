"""
    simulation.jl

Simulation runner and per-period metric collection.
"""

using DataFrames: DataFrame
using Statistics: mean

"""Safe mean that returns NaN on empty vectors."""
safe_mean(v) = isempty(v) ? NaN : mean(v)

"""
    collect_period_metrics(state) -> NamedTuple

Collect all per-period metrics from the state and accumulators.
"""
function collect_period_metrics(state::ModelState)
    p = state.params
    a = state.accum
    agents = state.agents
    broker = state.broker
    N = p.N

    # Prediction quality
    se = state.env.sigma_eps
    agent_holdout = compute_prediction_quality(a.agent_holdout_pred, a.agent_holdout_real; sigma_eps=se)
    broker_holdout = compute_prediction_quality(a.broker_holdout_pred, a.broker_holdout_real; sigma_eps=se)

    # Agent-level stats
    n_available = count(ag -> isempty(ag.active_matches), agents)
    mean_sat_self = mean(ag.satisfaction_self for ag in agents)
    mean_sat_broker = mean(ag.satisfaction_broker for ag in agents)

    return (
        period = state.period,
        # Match counts
        n_self_matches = a.n_self_matches,
        n_broker_standard = a.n_broker_standard,
        n_broker_principal = a.n_broker_principal,
        n_total_matches = a.n_self_matches + a.n_broker_standard + a.n_broker_principal,
        # Match quality
        q_self_mean = safe_mean(a.q_self),
        q_broker_standard_mean = safe_mean(a.q_broker_standard),
        q_broker_principal_mean = safe_mean(a.q_broker_principal),
        # Outsourcing
        n_demanders = a.n_demanders,
        n_outsourced = a.n_outsourced,
        outsourcing_rate = a.n_demanders > 0 ? a.n_outsourced / a.n_demanders : 0.0,
        # Access vs assessment
        access_count = a.access_count,
        assessment_count = a.assessment_count,
        # Prediction quality (holdout)
        agent_holdout_r2 = agent_holdout.r_squared,
        agent_holdout_bias = agent_holdout.bias,
        agent_holdout_rank = agent_holdout.rank_corr,
        broker_holdout_r2 = broker_holdout.r_squared,
        broker_holdout_bias = broker_holdout.bias,
        broker_holdout_rank = broker_holdout.rank_corr,
        # R2 gap
        r2_gap = broker_holdout.r_squared - agent_holdout.r_squared,
        # Broker state
        broker_reputation = broker.last_reputation,
        roster_size = a.roster_size,
        broker_history_size = broker.history_count,
        broker_cumulative_revenue = broker.cumulative_revenue,
        # Revenue
        broker_standard_revenue = a.broker_standard_revenue,
        broker_principal_revenue = a.broker_principal_revenue,
        # Capture metrics (Model 1)
        principal_mode_share = (a.n_broker_standard + a.n_broker_principal) > 0 ?
            a.n_broker_principal / (a.n_broker_standard + a.n_broker_principal) : 0.0,
        # Satisfaction
        mean_satisfaction_self = mean_sat_self,
        mean_satisfaction_broker = mean_sat_broker,
        # Market state
        n_available = n_available,
        # Network measures
        betweenness = state.cached_network.betweenness,
        constraint = state.cached_network.constraint,
        effective_size = state.cached_network.effective_size,
    )
end

"""
    run_simulation(params; verify=false, sort_by_pc1=false) -> (ModelState, DataFrame)

Initialize the model and run for T periods. Returns final state and metrics DataFrame.
"""
function run_simulation(params::ModelParams; verify::Bool = false, sort_by_pc1::Bool = false)
    state = initialize_model(params; sort_by_pc1=sort_by_pc1)
    rows = NamedTuple[]
    sizehint!(rows, params.T)

    for t in 1:params.T
        step_period!(state)
        verify && verify_invariants(state)
        push!(rows, collect_period_metrics(state))
    end

    df = DataFrame(rows)
    return (state, df)
end
