"""
    learning.jl

k-NN prediction for firms and brokers, tree construction, and predict-and-record wrappers.
"""

"""Fill `cache.idxs` and `cache.dists` with the `k_eff` nearest neighbors of `w_query`."""
@inline function _knn_query!(cache::PredictionCache, tree::KDTree,
                              w_query::AbstractVector{Float64}, k_eff::Int)
    if k_eff == length(cache.idxs)
        knn!(cache.idxs, cache.dists, tree, w_query, k_eff)
    else
        knn!(@view(cache.idxs[1:k_eff]), @view(cache.dists[1:k_eff]), tree, w_query, k_eff)
    end
    return nothing
end

"""
    _knn_predict!(cache, qs, k_eff, fallback) -> PredictionResult

Adaptive-bandwidth Gaussian-weighted k-NN prediction. Uses the k-th neighbor
distance as bandwidth so the kernel scales to local data density. Falls back
to `fallback` when all weights are near zero.
`cache.idxs` and `cache.dists` must be filled by a prior `_knn_query!` call.
"""
function _knn_predict!(cache::PredictionCache, qs::AbstractVector{Float64},
                       k_eff::Int, fallback::Float64)::PredictionResult
    # Adaptive bandwidth: k-th neighbor distance (furthest neighbor)
    @inbounds h = cache.dists[k_eff]
    inv2h2 = h > 1e-12 ? 1.0 / (2.0 * h * h) : 0.5  # fallback bandwidth=1 if all neighbors at same point

    # Pass 1: compute weights, weight sum, distance sum, outcome mean
    w_sum = 0.0
    dist_sum = 0.0
    q_mean = 0.0
    @inbounds for m in 1:k_eff
        wt = exp(-cache.dists[m]^2 * inv2h2)
        cache.weights[m] = wt
        w_sum += wt
        dist_sum += cache.dists[m]
        q_mean += qs[cache.idxs[m]]
    end
    mean_dist = dist_sum / k_eff
    if w_sum < 1e-12
        return PredictionResult(fallback, mean_dist, NaN)
    end
    # Pass 2: weighted prediction and neighbor variance
    q_hat = 0.0
    q_mean /= k_eff
    neighbor_var = 0.0
    @inbounds for m in 1:k_eff
        qm = qs[cache.idxs[m]]
        q_hat += cache.weights[m] * qm
        d = qm - q_mean
        neighbor_var += d * d
    end
    q_hat /= w_sum
    neighbor_var = k_eff > 1 ? neighbor_var / (k_eff - 1) : 0.0
    return PredictionResult(q_hat, mean_dist, neighbor_var)
end

"""
    predict_firm(firm, w_query, q_pub, k, tree, cache) -> PredictionResult

Predict match quality for worker type `w_query` at `firm` using k-NN on the firm's
history. Returns q_pub when history is empty.
"""
function predict_firm(firm::Firm, w_query::Vector{Float64},
                      q_pub::Float64, k::Int,
                      tree::Union{Nothing, KDTree},
                      cache::PredictionCache)::PredictionResult
    n = effective_history_size(firm)
    if tree === nothing || n == 0
        return PredictionResult(q_pub, Inf, NaN)
    end
    k_eff = min(k, n)
    _knn_query!(cache, tree, w_query, k_eff)
    return _knn_predict!(cache, firm.history_q, k_eff, q_pub)
end

"""
    _predict_stage1(broker, w_query, q_pub, k, tree, cache) -> Float64

Broker Stage 1: estimate worker-general quality from full cross-firm history.
Returns q_pub when history is empty.
"""
function _predict_stage1(broker::Broker, w_query::AbstractVector{Float64},
                         q_pub::Float64, k::Int,
                         tree::Union{Nothing, KDTree},
                         cache::PredictionCache)::Float64
    n = effective_history_size(broker)
    if tree === nothing || n == 0
        return q_pub
    end
    k_eff = min(k, n)
    _knn_query!(cache, tree, w_query, k_eff)
    return _knn_predict!(cache, broker.history_q, k_eff, q_pub).q_hat
end

"""
    _predict_stage2(w_query, k, tree, residuals, cache) -> PredictionResult

Broker Stage 2: estimate firm-specific residual via k-NN on precomputed residuals.
Returns zero residual when the tree is empty or missing.
"""
function _predict_stage2(w_query::Vector{Float64}, k::Int,
                         tree::Union{Nothing, KDTree},
                         residuals::Vector{Float64},
                         cache::PredictionCache)::PredictionResult
    n_firm = length(residuals)
    if n_firm == 0 || tree === nothing
        return PredictionResult(0.0, Inf, NaN)
    end
    k_eff = min(k, n_firm)
    _knn_query!(cache, tree, w_query, k_eff)
    return _knn_predict!(cache, residuals, k_eff, 0.0)
end

"""
    predict_broker(broker, w_query, firm_idx, q_pub, k, trees, cache) -> PredictionResult

Two-stage decomposition prediction (spec 5b). Stage 1 estimates worker-general
quality from full history; Stage 2 estimates firm-specific residual.
"""
function predict_broker(broker::Broker, w_query::Vector{Float64},
                        firm_idx::Int, q_pub::Float64,
                        k::Int, trees::PeriodTrees,
                        cache::PredictionCache)::PredictionResult
    mu_hat = _predict_stage1(broker, w_query, q_pub, k,
                              trees.broker_s1_tree, cache)
    s2_tree = get(trees.broker_s2_trees, firm_idx, nothing)
    s2 = if s2_tree === nothing
        PredictionResult(0.0, Inf, NaN)
    else
        _predict_stage2(w_query, k, s2_tree, trees.broker_s2_residuals[firm_idx], cache)
    end
    return PredictionResult(mu_hat + s2.q_hat, s2.mean_dist, s2.neighbor_var)
end

"""
    build_period_trees(state, client_firm_indices) -> PeriodTrees

Build KDTrees for all firms with history, the broker's Stage 1 (full history),
and Stage 2 trees with precomputed residuals for each client firm index.
"""
function build_period_trees(state::ModelState,
                            client_firm_indices::Vector{Int})::PeriodTrees
    # Firm trees
    firm_trees = Vector{Union{Nothing, KDTree}}(nothing, length(state.firms))
    for (j, firm) in enumerate(state.firms)
        n_firm = effective_history_size(firm)
        if n_firm > 0
            firm_trees[j] = KDTree(@view firm.history_w[:, 1:n_firm])
        end
    end

    # Broker Stage 1 tree
    broker = state.broker
    n_broker = effective_history_size(broker)
    broker_s1_tree = n_broker > 0 ?
        KDTree(@view broker.history_w[:, 1:n_broker]) : nothing

    # Broker Stage 2: per-client trees with precomputed residuals
    broker_s2_trees = Dict{Int, KDTree}()
    broker_s2_residuals = Dict{Int, Vector{Float64}}()
    cache = PredictionCache(state.params.k_nn)
    for j in client_firm_indices
        firm_mask = findall(i -> broker.history_firm_idx[i] == j, 1:n_broker)
        isempty(firm_mask) && continue
        firm_w = broker.history_w[:, firm_mask]
        firm_q = @view broker.history_q[firm_mask]
        residuals = Vector{Float64}(undef, length(firm_mask))
        for col in eachindex(firm_mask)
            mu_hat = _predict_stage1(broker, @view(firm_w[:, col]), state.cal.q_pub,
                                      state.params.k_nn, broker_s1_tree, cache)
            residuals[col] = firm_q[col] - mu_hat
        end
        broker_s2_residuals[j] = residuals
        broker_s2_trees[j] = KDTree(firm_w)
    end

    return PeriodTrees(firm_trees, broker_s1_tree, broker_s2_trees, broker_s2_residuals)
end

"""
    predict_and_record_firm!(accum, firm, w_query, q_pub, k, tree, cache) -> Float64

Predict via firm k-NN, push mean_dist and neighbor_var to `accum`, return q_hat.
"""
function predict_and_record_firm!(accum::PeriodAccumulators,
                                  firm::Firm, w_query::Vector{Float64},
                                  q_pub::Float64, k::Int,
                                  tree::Union{Nothing, KDTree},
                                  cache::PredictionCache)::Float64
    result = predict_firm(firm, w_query, q_pub, k, tree, cache)
    push!(accum.firm_mean_dists, result.mean_dist)
    push!(accum.firm_neighbor_vars, result.neighbor_var)
    return result.q_hat
end

"""
    predict_and_record_broker!(accum, broker, w_query, firm_idx, q_pub, k, trees, cache) -> Float64

Predict via broker two-stage k-NN, push mean_dist and neighbor_var to `accum`, return q_hat.
"""
function predict_and_record_broker!(accum::PeriodAccumulators,
                                     broker::Broker, w_query::Vector{Float64},
                                     firm_idx::Int, q_pub::Float64, k::Int,
                                     trees::PeriodTrees,
                                     cache::PredictionCache)::Float64
    result = predict_broker(broker, w_query, firm_idx, q_pub, k, trees, cache)
    push!(accum.broker_mean_dists, result.mean_dist)
    push!(accum.broker_neighbor_vars, result.neighbor_var)
    return result.q_hat
end
