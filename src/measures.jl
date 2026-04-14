"""
    measures.jl

Network position measures (betweenness, Burt's constraint, effective size)
and prediction quality metrics (R², bias, rank correlation).
All measures are computed on the single graph G which includes the broker node.

Betweenness centrality follows Brandes (2001), adapted for single-node
computation on undirected unweighted graphs, with a CSR adjacency structure
for allocation-free neighbor iteration inside threaded BFS.
"""

using Graphs: SimpleGraph, neighbors, nv, ne, has_edge
using StatsBase: corspearman
using Statistics: var, mean
using Base.Threads: @threads, nthreads

# ─────────────────────────────────────────────────────────────────────────────
# Prediction quality
# ─────────────────────────────────────────────────────────────────────────────

"""
    compute_prediction_quality(predicted, realized; sigma_eps=0.10) -> PredictionQuality

Compute R², bias, and Spearman rank correlation between predicted and realized values.
Returns NaN for all metrics if fewer than 5 observations or if the variance of realized
values is below sigma_eps^2 / 6 (too little signal to meaningfully evaluate R²).
"""
function compute_prediction_quality(predicted::Vector{Float64}, realized::Vector{Float64};
                                    sigma_eps::Float64 = 0.10)::PredictionQuality
    n = length(predicted)
    n < 5 && return PredictionQuality(NaN, NaN, NaN)
    @assert n == length(realized)

    var_realized = var(realized)
    var_realized < sigma_eps^2 / 6 && return PredictionQuality(NaN, NaN, NaN)

    mse = sum((predicted .- realized).^2) / n
    r_squared = 1.0 - mse / var_realized
    bias = mean(predicted .- realized)
    rank_corr = corspearman(predicted, realized)

    return PredictionQuality(r_squared, bias, rank_corr)
end

# ─────────────────────────────────────────────────────────────────────────────
# CSR adjacency structure (allocation-free neighbor iteration)
# ─────────────────────────────────────────────────────────────────────────────

"""Compressed Sparse Row adjacency for allocation-free neighbor iteration.
Built once from a SimpleGraph before entering threaded loops."""
struct CSRAdjacency
    offsets::Vector{Int}   # length n+1; neighbors of v are adj[offsets[v]:offsets[v+1]-1]
    adj::Vector{Int}       # flat neighbor list
end

"""Build CSR adjacency from a SimpleGraph. O(n + m) time and space."""
function build_csr(G::SimpleGraph)::CSRAdjacency
    n = nv(G)
    offsets = Vector{Int}(undef, n + 1)
    # Count degrees
    offsets[1] = 1
    @inbounds for v in 1:n
        offsets[v + 1] = offsets[v] + length(neighbors(G, v))
    end
    total = offsets[n + 1] - 1
    adj = Vector{Int}(undef, total)
    # Fill adjacency
    @inbounds for v in 1:n
        idx = offsets[v]
        for w in neighbors(G, v)
            adj[idx] = w
            idx += 1
        end
    end
    return CSRAdjacency(offsets, adj)
end

"""Iterate neighbors of v in CSR. Returns a range into csr.adj."""
@inline function csr_neighbors(csr::CSRAdjacency, v::Int)
    @inbounds return csr.offsets[v]:(csr.offsets[v + 1] - 1)
end

# ─────────────────────────────────────────────────────────────────────────────
# Betweenness centrality (Brandes 2001, single-node, threaded)
# ─────────────────────────────────────────────────────────────────────────────

"""Per-thread scratch buffers for Brandes BFS, reused across source vertices."""
mutable struct BrandesWorkspace
    n::Int
    sigma::Vector{Int}
    dist::Vector{Int}
    delta::Vector{Float64}
    queue::Vector{Int}
    stack::Vector{Int}
    # Flat predecessor storage: pred_data[pred_off[w]:pred_off[w]+pred_count[w]-1]
    pred_off::Vector{Int}       # length n+1 (prefix offsets, rebuilt per source)
    pred_data::Vector{Int}      # flat predecessor list, pre-allocated
    pred_count::Vector{Int}     # per-node predecessor count (reset each source)
end

function BrandesWorkspace(n::Int, max_preds::Int)
    BrandesWorkspace(n,
        Vector{Int}(undef, n), Vector{Int}(undef, n), Vector{Float64}(undef, n),
        Vector{Int}(undef, n), Vector{Int}(undef, n),
        Vector{Int}(undef, n + 1), Vector{Int}(undef, max(max_preds, 1)),
        Vector{Int}(undef, n))
end

"""Ensure workspace is sized for n vertices and max_preds predecessors."""
function ensure_workspace!(ws::BrandesWorkspace, n::Int, max_preds::Int)
    if ws.n < n
        resize!(ws.sigma, n); resize!(ws.dist, n); resize!(ws.delta, n)
        resize!(ws.queue, n); resize!(ws.stack, n)
        resize!(ws.pred_off, n + 1); resize!(ws.pred_count, n)
        ws.n = n
    end
    if length(ws.pred_data) < max_preds
        resize!(ws.pred_data, max_preds)
    end
    return ws
end

# Module-level thread-local workspaces
const _BRANDES_WS = Ref{Vector{BrandesWorkspace}}(BrandesWorkspace[])

"""
    compute_betweenness(G, node) -> Float64

Freeman betweenness centrality for a single node using the Brandes (2001)
algorithm adapted for undirected unweighted graphs.

The raw accumulation Σ_s δ_s•(node) counts each unordered (s,t) pair from
both BFS directions. For undirected graphs the standard normalization is
(n-1)(n-2)/2 unordered pairs, and the double-counting cancels with a factor
of 2, giving a combined divisor of (n-1)(n-2) (Brandes, 2001, p. 9).

Uses a CSR adjacency structure for allocation-free neighbor iteration and
pre-allocated per-thread workspaces. The BFS + back-propagation is O(m) per
source, O(nm) total, matching the Brandes complexity bound.
"""
function compute_betweenness(G::SimpleGraph, node::Int)::Float64
    n = nv(G)
    n <= 2 && return 0.0

    # Build CSR once (O(n+m), outside threaded loop)
    csr = build_csr(G)
    m = ne(G)

    # Upper bound on total predecessors per source: each edge contributes at
    # most one predecessor entry per direction, so total_preds <= 2m.
    max_preds = 2 * m + 1

    # Initialize/resize thread-local workspaces before @threads
    n_threads = nthreads()
    ws_vec = _BRANDES_WS[]
    if length(ws_vec) != n_threads
        ws_vec = [BrandesWorkspace(n, max_preds) for _ in 1:n_threads]
        _BRANDES_WS[] = ws_vec
    end
    for t in 1:n_threads
        ensure_workspace!(ws_vec[t], n, max_preds)
    end

    partial_bc = zeros(n_threads)

    # Inner function: run BFS + back-propagation for a range of sources.
    # Extracted to avoid closure boxing and to enable manual chunking.
    function _brandes_chunk!(ws::BrandesWorkspace, csr::CSRAdjacency,
                             n::Int, node::Int, s_range, tid::Int)
        sigma = ws.sigma; dist = ws.dist; delta = ws.delta
        queue = ws.queue; stack = ws.stack
        pred_off = ws.pred_off; pred_data = ws.pred_data; pred_count = ws.pred_count
        local_bc = 0.0

        for s in s_range
            s == node && continue

            # ── Reset per-source state ──
            @inbounds for i in 1:n
                sigma[i] = 0; dist[i] = -1; delta[i] = 0.0; pred_count[i] = 0
            end
            sigma[s] = 1; dist[s] = 0
            queue[1] = s; q_head = 1; q_tail = 1; stack_len = 0

            # ── BFS ──
            @inbounds while q_head <= q_tail
                v = queue[q_head]; q_head += 1
                stack_len += 1; stack[stack_len] = v
                for idx in csr_neighbors(csr, v)
                    w = csr.adj[idx]
                    if dist[w] < 0
                        dist[w] = dist[v] + 1
                        q_tail += 1; queue[q_tail] = w
                    end
                    if dist[w] == dist[v] + 1
                        sigma[w] += sigma[v]
                        pred_count[w] += 1
                    end
                end
            end

            # ── Build predecessor offset table ──
            @inbounds begin
                pred_off[1] = 1
                for i in 1:n
                    pred_off[i + 1] = pred_off[i] + pred_count[i]
                end
            end

            # ── Fill predecessor data ──
            @inbounds for i in 1:n; pred_count[i] = 0; end
            @inbounds for k in 1:stack_len
                v = stack[k]
                for idx in csr_neighbors(csr, v)
                    w = csr.adj[idx]
                    if dist[w] == dist[v] + 1
                        slot = pred_off[w] + pred_count[w]
                        pred_data[slot] = v
                        pred_count[w] += 1
                    end
                end
            end

            # ── Brandes back-propagation (Theorem 6) ──
            @inbounds while stack_len > 0
                w = stack[stack_len]; stack_len -= 1
                sw = sigma[w]
                sw == 0 && continue
                coeff = (1.0 + delta[w]) / sw
                p_begin = pred_off[w]
                p_end = p_begin + pred_count[w] - 1
                for p in p_begin:p_end
                    v = pred_data[p]
                    delta[v] += sigma[v] * coeff
                end
                if w == node
                    local_bc += delta[w]
                end
            end
        end  # for s

        partial_bc[tid] += local_bc
    end

    # Chunk sources across threads (one task per thread, not per source).
    # This reduces scheduling overhead from O(n) task creations to O(nthreads).
    if n_threads > 1
        chunk_size = cld(n, n_threads)
        @threads for tid in 1:n_threads
            s_lo = (tid - 1) * chunk_size + 1
            s_hi = min(tid * chunk_size, n)
            _brandes_chunk!(ws_vec[tid], csr, n, node, s_lo:s_hi, tid)
        end
    else
        _brandes_chunk!(ws_vec[1], csr, n, node, 1:n, 1)
    end

    bc = sum(partial_bc)

    # Normalization for undirected graphs (Brandes, 2001):
    # Raw sum counts each unordered pair (s,t) from both directions.
    # Standard normalized betweenness divides by (n-1)(n-2)/2 pairs and
    # corrects for double-counting by dividing by 2, yielding (n-1)(n-2).
    norm_factor = Float64((n - 1) * (n - 2))
    return norm_factor > 0.0 ? bc / norm_factor : 0.0
end

# ─────────────────────────────────────────────────────────────────────────────
# Burt's constraint and effective size
# ─────────────────────────────────────────────────────────────────────────────

"""
    compute_burt_constraint(G, node) -> Float64

Burt's network constraint: C = Σ_j (p_ij + Σ_{h≠i,j} p_ih · p_hj)².
Returns 1.0 if isolated.
"""
function compute_burt_constraint(G::SimpleGraph, node::Int)::Float64
    nbrs = neighbors(G, node)
    deg = length(nbrs)
    deg == 0 && return 1.0
    p = 1.0 / deg

    constraint = 0.0
    for j in nbrs
        c_ij = p
        for h in nbrs
            h == j && continue
            if has_edge(G, h, j)
                c_ij += p * p
            end
        end
        constraint += c_ij^2
    end
    return constraint
end

"""
    compute_effective_size(G, node) -> Float64

Burt's effective size: ES = |N(i)| - Σ_j p_ij Σ_{h≠i} p_ih · m_jh.
Returns 0.0 if isolated.
"""
function compute_effective_size(G::SimpleGraph, node::Int)::Float64
    nbrs = neighbors(G, node)
    deg = length(nbrs)
    deg == 0 && return 0.0
    p = 1.0 / deg

    redundancy = 0.0
    for j in nbrs
        for h in nbrs
            h == j && continue
            if has_edge(G, j, h)
                redundancy += p * p
            end
        end
    end
    return deg - redundancy
end

"""
    update_cached_network_measures!(state)

Recompute betweenness, constraint, and effective size for the broker node.
"""
function update_cached_network_measures!(state::ModelState)
    broker_node = state.broker.node_id
    state.cached_network.betweenness = compute_betweenness(state.G, broker_node)
    state.cached_network.constraint = compute_burt_constraint(state.G, broker_node)
    state.cached_network.effective_size = compute_effective_size(state.G, broker_node)
    return nothing
end
