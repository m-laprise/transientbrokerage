"""
    search.jl

Two-component self-search (known neighbors + strangers) and broker greedy allocation.
"""

using Graphs: neighbors, has_edge
using Random: AbstractRNG
using StatsBase: sample

# ─────────────────────────────────────────────────────────────────────────────
# Self-search
# ─────────────────────────────────────────────────────────────────────────────

"""
    self_search(agent, agents, G, broker_node, params, rng, d_i, r; ws, proposals)

Self-search for agent with d_i demand slots. Builds a candidate pool from
known neighbors (historical average) and strangers (NN prediction).
Appends up to d_i proposals to `proposals` (or a fresh vector if not provided).
"""
function self_search(agent::Agent, agents::Vector{Agent}, G::SimpleGraph,
                     broker_node::Int, params::ModelParams, rng::AbstractRNG,
                     d_i::Int, r::Float64;
                     ws::Union{SimWorkspace, Nothing} = nothing,
                     proposals::Union{Vector{ProposedMatch}, Nothing} = nothing)
    out = proposals === nothing ? ProposedMatch[] : proposals
    d_i <= 0 && return out

    K = params.K
    agent_id = agent.id
    N = length(agents)

    # Workspace buffers (allocated locally if none provided; preferred path
    # passes a ws reused across agents within a single period).
    if ws === nothing
        neighbor_ids = Int[]; neighbor_evals = Float64[]
        stranger_ids = Int[]; stranger_evals = Float64[]
        eligible = Int[]; nbr_mask = fill(false, N + 1)
        stranger_sample = Int[]
        local_marked = Int[]
    else
        neighbor_ids = ws.neighbor_ids; empty!(neighbor_ids)
        neighbor_evals = ws.neighbor_evals; empty!(neighbor_evals)
        stranger_ids = ws.stranger_ids; empty!(stranger_ids)
        stranger_evals = ws.stranger_evals; empty!(stranger_evals)
        eligible = ws.eligible; empty!(eligible)
        stranger_sample = ws.stranger_sample; empty!(stranger_sample)
        if length(ws.nbr_mask) < N + 1
            old_len = length(ws.nbr_mask)
            resize!(ws.nbr_mask, N + 1)
            # resize! on Vector{Bool} leaves new slots uninitialized; zero them.
            @inbounds for i in (old_len + 1):(N + 1)
                ws.nbr_mask[i] = false
            end
        end
        nbr_mask = ws.nbr_mask
        local_marked = ws.nbr_marked; empty!(local_marked)
    end

    # ── Build candidate pool (once, shared across all demand slots) ──

    # Pass 1: walk neighbors. Mark them in nbr_mask for O(1) membership later,
    # and collect eligible known neighbors (those with a non-NaN partner mean).
    # local_marked tracks what we set so we can clear only those at the end.
    @inbounds for nbr in neighbors(G, agent_id)
        nbr == broker_node && continue  # skip broker node
        (nbr < 1 || nbr > N) && continue
        nbr_mask[nbr] = true
        push!(local_marked, nbr)
        available_capacity(agents[nbr], K) <= 0 && continue
        mean_q = partner_mean(agent, nbr)
        if !isnan(mean_q)
            push!(neighbor_ids, nbr)
            push!(neighbor_evals, mean_q)
        end
    end

    # Strangers: sample from non-neighbors with capacity. Use bitset for O(1) check.
    if params.n_strangers > 0
        @inbounds for j in 1:N
            j == agent_id && continue
            nbr_mask[j] && continue
            available_capacity(agents[j], K) <= 0 && continue
            push!(eligible, j)
        end

        n_sample = min(params.n_strangers, length(eligible))
        if n_sample > 0
            # Keep the original allocating `sample` to preserve the exact RNG
            # stream (and hence full determinism of the simulation).
            sampled = sample(rng, eligible, n_sample; replace=false)
            @inbounds for j in sampled
                q_hat = predict_nn!(agent.nn, agent.predict_buf, agents[j].type)
                push!(stranger_ids, j)
                push!(stranger_evals, q_hat)
            end
        end
    end

    # Clear bitset (only the entries we touched)
    @inbounds for nbr in local_marked
        nbr_mask[nbr] = false
    end

    # No candidates at all
    if isempty(neighbor_ids) && isempty(stranger_ids)
        return out
    end

    # ── Select counterparty for each demand slot ──
    for _ in 1:d_i
        best_id = 0
        best_eval = -Inf
        n_tied = 0

        @inbounds for idx in eachindex(neighbor_ids)
            v = neighbor_evals[idx]
            id = neighbor_ids[idx]
            if v > best_eval
                best_eval = v; best_id = id; n_tied = 1
            elseif v == best_eval
                n_tied += 1
                if rand(rng) < 1.0 / n_tied
                    best_id = id
                end
            end
        end
        @inbounds for idx in eachindex(stranger_ids)
            v = stranger_evals[idx]
            id = stranger_ids[idx]
            if v > best_eval
                best_eval = v; best_id = id; n_tied = 1
            elseif v == best_eval
                n_tied += 1
                if rand(rng) < 1.0 / n_tied
                    best_id = id
                end
            end
        end

        if best_id == 0 || best_eval <= r
            break
        end
        push!(out, ProposedMatch(agent_id, best_id, :self, best_eval, false))
    end

    return out
end

# ─────────────────────────────────────────────────────────────────────────────
# Broker allocation
# ─────────────────────────────────────────────────────────────────────────────

"""
    broker_allocate(broker, client_demands, agents, params, rng, r; ws, proposals)

Greedy best-pair allocation from the broker's quality matrix. Builds a batched
NN prediction over unique (demander, roster_member) pairs, then iterates in
descending quality order. Appends matches to `proposals` (or a fresh vector).
"""
function broker_allocate(broker::Broker, client_demands::Vector{Tuple{Int, Int}},
                         agents::Vector{Agent}, params::ModelParams,
                         rng::AbstractRNG, r::Float64;
                         ws::Union{SimWorkspace, Nothing} = nothing,
                         proposals::Union{Vector{ProposedMatch}, Nothing} = nothing)
    out = proposals === nothing ? ProposedMatch[] : proposals
    isempty(client_demands) && return out

    K = params.K
    d = params.d
    d2 = 2 * d
    h_b = params.h_b
    N = length(agents)

    # ── Workspace buffers ─────────────────────────────────────────────────
    if ws === nothing
        roster_members = Int[]; roster_capacity = Int[]
        unique_demanders = Int[]; demander_remaining = Int[]
        demander_idx = zeros(Int, N); demander_touched = Int[]
    else
        roster_members = ws.roster_members; empty!(roster_members)
        roster_capacity = ws.roster_capacity; empty!(roster_capacity)
        unique_demanders = ws.unique_demanders; empty!(unique_demanders)
        demander_remaining = ws.demander_remaining; empty!(demander_remaining)
        demander_touched = ws.demander_touched; empty!(demander_touched)
        if length(ws.demander_idx) < N
            old = length(ws.demander_idx)
            resize!(ws.demander_idx, N)
            @inbounds for i in (old+1):N; ws.demander_idx[i] = 0; end
        end
        demander_idx = ws.demander_idx
        # demander_idx is sparse-cleared after each call via demander_touched
    end

    # ── Deduplication via pre-allocated index array (B) ───────────────────
    for (aid, cnt) in client_demands
        idx = demander_idx[aid]
        if idx == 0
            push!(unique_demanders, aid)
            idx = length(unique_demanders)
            demander_idx[aid] = idx
            push!(demander_touched, aid)
            push!(demander_remaining, cnt)
        else
            demander_remaining[idx] += cnt
        end
    end
    n_unique = length(unique_demanders)
    n_unique == 0 && (@goto cleanup; return out)

    # Available roster members with capacity
    for rid in broker.roster
        (rid < 1 || rid > N) && continue
        available_capacity(agents[rid], K) > 0 || continue
        push!(roster_members, rid)
    end
    if isempty(roster_members); @goto cleanup; end
    n_roster = length(roster_members)

    # ── Batched Q-matrix build (A) ────────────────────────────────────────
    # Grow Q
    if ws !== nothing && (size(ws.Q, 1) < n_unique || size(ws.Q, 2) < n_roster)
        ws.Q = Matrix{Float64}(undef, max(n_unique, size(ws.Q, 1)),
                                      max(n_roster, size(ws.Q, 2)))
    end
    Q = ws === nothing ? Matrix{Float64}(undef, n_unique, n_roster) : ws.Q

    # Count non-self pairs
    n_pairs = n_unique * n_roster
    n_self = 0
    @inbounds for ri in 1:n_roster
        if demander_idx[roster_members[ri]] > 0
            n_self += 1
        end
    end
    n_pairs -= n_self

    # Grow batch buffers
    if ws !== nothing
        if size(ws.Z_batch, 1) != d2 || size(ws.Z_batch, 2) < n_pairs
            cap = max(n_pairs, 2 * size(ws.Z_batch, 2), 256)
            ws.Z_batch = Matrix{Float64}(undef, d2, cap)
            ws.H_batch = Matrix{Float64}(undef, h_b, cap)
            resize!(ws.Y_batch, cap)
        end
    end
    Z_batch = ws === nothing ? Matrix{Float64}(undef, d2, n_pairs) : ws.Z_batch
    H_batch = ws === nothing ? Matrix{Float64}(undef, h_b, n_pairs) : ws.H_batch
    Y_batch = ws === nothing ? Vector{Float64}(undef, n_pairs) : ws.Y_batch

    # Fill Z_batch
    col = 0
    @inbounds for ri in 1:n_roster
        rid = roster_members[ri]
        xj = agents[rid].type
        for di in 1:n_unique
            did = unique_demanders[di]
            if did == rid
                Q[di, ri] = -Inf
            else
                col += 1
                xi = agents[did].type
                for k in 1:d
                    Z_batch[k, col] = xi[k]
                    Z_batch[d + k, col] = xj[k]
                end
            end
        end
    end

    # One batched BLAS forward pass
    predict_nn_batch!(broker.nn, H_batch, Y_batch, Z_batch, n_pairs)

    # Scatter into Q
    col = 0
    @inbounds for ri in 1:n_roster
        rid = roster_members[ri]
        for di in 1:n_unique
            if unique_demanders[di] != rid
                col += 1
                Q[di, ri] = Y_batch[col]
            end
        end
    end

    # ── Sorted greedy allocation (D) ──────────────────────────────────────
    # Sort (negated_val, flat_index) pairs in-place. Negation makes ascending
    # sort equivalent to descending-by-value. QuickSort is O(1) extra memory.
    n_entries = n_unique * n_roster
    sort_pairs = ws === nothing ? Vector{Tuple{Float64,Int}}(undef, n_entries) : ws.sort_pairs
    if length(sort_pairs) < n_entries
        resize!(sort_pairs, n_entries)
        if ws !== nothing; resize!(ws.sort_pairs, n_entries); sort_pairs = ws.sort_pairs; end
    end

    idx = 0
    @inbounds for ri in 1:n_roster
        for di in 1:n_unique
            idx += 1
            sort_pairs[idx] = (-Q[di, ri], idx)
        end
    end
    sort!(view(sort_pairs, 1:n_entries), alg=QuickSort)

    # Capacity tracking
    resize!(roster_capacity, n_roster)
    @inbounds for ri in 1:n_roster
        roster_capacity[ri] = available_capacity(agents[roster_members[ri]], K)
    end

    # Iterate sorted entries
    @inbounds for k in 1:n_entries
        neg_val, flat = sort_pairs[k]
        val = -neg_val
        val == -Inf && break
        val <= r && break

        di = (flat - 1) % n_unique + 1
        ri = (flat - 1) ÷ n_unique + 1

        demander_remaining[di] <= 0 && continue
        roster_capacity[ri] <= 0 && continue

        push!(out, ProposedMatch(
            unique_demanders[di],
            roster_members[ri],
            :broker, val, false
        ))

        demander_remaining[di] -= 1
        roster_capacity[ri] -= 1
    end

    @label cleanup
    # Sparse-clear demander_idx (only entries we touched)
    @inbounds for aid in demander_touched
        demander_idx[aid] = 0
    end

    return out
end
