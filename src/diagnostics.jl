"""
    diagnostics.jl

State snapshots for debugging and inspection.
"""

"""
    diagnostic_summary(state) -> Dict{String, Any}

Snapshot of key state variables for debugging. Uses `effective_history_size`
for history counts.
"""
function diagnostic_summary(state::ModelState)::Dict{String, Any}
    n_available = count(w -> w.status == available, state.workers)
    n_employed = count(w -> w.status == employed, state.workers)
    n_staffed = count(w -> w.status == staffed, state.workers)
    firm_hist_sizes = [effective_history_size(f) for f in state.firms]

    return Dict{String, Any}(
        "period" => state.period,
        "n_workers" => length(state.workers),
        "n_firms" => length(state.firms),
        "n_available" => n_available,
        "n_employed" => n_employed,
        "n_staffed" => n_staffed,
        "open_vacancies" => sum(state.open_vacancies),
        "broker_pool_size" => length(state.broker.pool),
        "broker_history_size" => effective_history_size(state.broker),
        "broker_reputation" => state.broker.last_reputation,
        "broker_has_had_clients" => state.broker.has_had_clients,
        "mean_firm_history_size" => mean(firm_hist_sizes),
        "mean_satisfaction_internal" => mean(f.satisfaction_internal for f in state.firms),
        "mean_satisfaction_broker" => mean(f.satisfaction_broker for f in state.firms),
        "betweenness" => state.cached_network.betweenness,
        "constraint" => state.cached_network.constraint,
        "effective_size" => state.cached_network.effective_size,
        "next_firm_id" => state.next_firm_id,
        "r_base" => state.cal.r_base,
        "f_bar" => state.cal.f_bar,
        "q_pub" => state.cal.q_pub,
    )
end
