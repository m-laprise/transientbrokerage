"""
    diagnostics.jl

State snapshots for debugging and inspection.
"""

using Statistics: mean

"""
    diagnostic_summary(state) -> Dict{String, Any}

Snapshot of key state variables for debugging. Quick-inspect Dict suitable
for printing or logging during development.
"""
function diagnostic_summary(state::ModelState)::Dict{String, Any}
    agents = state.agents
    broker = state.broker
    N = state.params.N
    agent_hist = [a.history_count for a in agents]

    return Dict{String, Any}(
        "period" => state.period,
        "N" => N,
        "n_active_matches" => sum(length(a.active_matches) for a in agents) ÷ 2,
        "mean_agent_history" => mean(agent_hist),
        "max_agent_history" => maximum(agent_hist),
        "broker_history_size" => broker.history_count,
        "broker_roster_size" => length(broker.roster),
        "broker_reputation" => broker.last_reputation,
        "broker_has_had_clients" => broker.has_had_clients,
        "broker_cumulative_revenue" => broker.cumulative_revenue,
        "mean_satisfaction_self" => mean(a.satisfaction_self for a in agents),
        "mean_satisfaction_broker" => mean(a.satisfaction_broker for a in agents),
        "mean_periods_alive" => mean(a.periods_alive for a in agents),
        "n_on_roster" => count(a -> a.on_roster, agents),
        "betweenness" => state.cached_network.betweenness,
        "constraint" => state.cached_network.constraint,
        "effective_size" => state.cached_network.effective_size,
        "q_pub" => state.cal.q_pub,
        "r" => state.cal.r,
        "phi" => state.cal.phi,
    )
end
