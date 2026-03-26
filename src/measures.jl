"""
    measures.jl

Prediction quality measures and network position measures (betweenness, Burt's
constraint, effective size) on the combined graph.
"""

# ── Prediction quality ──

"""
    compute_prediction_quality(predicted, realized) -> PredictionQuality

R-squared, bias, and Spearman rank correlation over paired prediction/outcome vectors.
Returns NaN for all fields when fewer than 5 observations.
"""
function compute_prediction_quality(predicted::Vector{Float64},
                                    realized::Vector{Float64})::PredictionQuality
    n = length(predicted)
    n < 5 && return PredictionQuality(NaN, NaN, NaN)
    mse = 0.0
    bias = 0.0
    @inbounds for i in 1:n
        e = predicted[i] - realized[i]
        mse += e * e
        bias += e
    end
    mse /= n
    bias /= n
    var_q = var(realized)
    r2 = var_q > 0 ? 1.0 - mse / var_q : NaN
    rank_corr = corspearman(predicted, realized)
    return PredictionQuality(r2, bias, rank_corr)
end

# ── Network measures ──

"""
    build_combined_graph(state) -> (SimpleGraph{Int}, Int)

Assemble the combined graph for network measures (§4, §8 step 6.1).
Nodes: workers 1:N_W, firms N_W+1:N_W+N_F, broker N_W+N_F+1.
Edges: G_S (worker-worker), G_E (worker-firm employment), broker pool (worker-broker).
Returns the graph and the broker node index.
"""
function build_combined_graph(state::ModelState)::Tuple{SimpleGraph{Int}, Int}
    N_W = state.params.N_W
    N_F = length(state.firms)
    n_total = N_W + N_F + 1
    broker_node = n_total

    G = SimpleGraph(n_total)

    # G_S edges (worker-worker)
    for e in edges(state.G_S)
        add_edge!(G, src(e), dst(e))
    end

    # G_E edges (worker-firm employment)
    for (j, firm) in enumerate(state.firms)
        firm_node = N_W + j
        for wid in firm.employees
            add_edge!(G, wid, firm_node)
        end
    end

    # Broker pool edges (worker-broker)
    for wid in state.broker.pool
        add_edge!(G, wid, broker_node)
    end

    return (G, broker_node)
end

"""
    compute_betweenness(G, node) -> Float64

Normalized Freeman betweenness centrality for a single node.
"""
function compute_betweenness(G::SimpleGraph, node::Int)::Float64
    bc = betweenness_centrality(G)
    return bc[node]
end

"""
    compute_burt_constraint(G, node) -> Float64

Burt's network constraint on node's ego network (Burt, 1992):
C = sum_j (p_ij + sum_{q!=i,j} p_iq * p_qj)^2
where p_ij = 1/deg(i) and p_qj = 1/deg(q) for unweighted graphs.
Returns 1.0 if node has no neighbors.
"""
function compute_burt_constraint(G::SimpleGraph, node::Int)::Float64
    nbrs = neighbors(G, node)
    deg = length(nbrs)
    deg == 0 && return 1.0

    p_i = 1.0 / deg
    constraint = 0.0
    for j in nbrs
        indirect = 0.0
        for q in nbrs
            q == j && continue
            if has_edge(G, q, j)
                indirect += p_i * (1.0 / length(neighbors(G, q)))
            end
        end
        constraint += (p_i + indirect)^2
    end
    return constraint
end

"""
    compute_effective_size(G, node) -> Float64

Burt's effective size: non-redundant contacts in the ego network (Burt, 1992).
ES = |N(i)| - sum_j p_ij * sum_{q!=i} p_iq * m_jq
where m_jq = 1 if j and q are connected, p_ij = 1/deg(i) for unweighted graphs.
Returns 0.0 if node has no neighbors.
"""
function compute_effective_size(G::SimpleGraph, node::Int)::Float64
    nbrs = neighbors(G, node)
    deg = length(nbrs)
    deg == 0 && return 0.0

    p = 1.0 / deg
    redundancy = 0.0
    for j in nbrs
        for q in nbrs
            q == j && continue
            if has_edge(G, j, q)
                redundancy += p * p
            end
        end
    end
    return deg - redundancy
end

"""
    update_cached_network_measures!(state)

Build the combined graph and compute betweenness, Burt's constraint, and
effective size for the broker node. Called every M periods.
"""
function update_cached_network_measures!(state::ModelState)
    G, broker_node = build_combined_graph(state)
    state.cached_network.betweenness = compute_betweenness(G, broker_node)
    state.cached_network.constraint = compute_burt_constraint(G, broker_node)
    state.cached_network.effective_size = compute_effective_size(G, broker_node)
    return nothing
end
