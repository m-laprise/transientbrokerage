"""
    search.jl

Two-component self-search (known neighbors + strangers) and broker greedy allocation.
"""

using Graphs: neighbors, has_edge
using Random: AbstractRNG
using StatsBase: sample

@inline function current_open_capacity(agents::Vector{Agent},
                                       agent_id::Int,
                                       K::Int,
                                       reserved_capacity::Union{Vector{Int}, Nothing})
    if isnothing(reserved_capacity)
        return available_capacity(agents[agent_id], K)
    end
    return available_capacity(agents[agent_id], K, reserved_capacity[agent_id])
end

# ─────────────────────────────────────────────────────────────────────────────
# Self-search
# ─────────────────────────────────────────────────────────────────────────────

"""
    self_search(agent, agents, G, broker_node, params, rng, d_i, r; ws, proposals)

Self-search for agent with d_i demand slots. Builds a candidate pool from
known neighbors (historical average) and strangers (NN prediction), then
fills slots greedily subject to each candidate's current-period remaining
capacity. Appends up to d_i proposals to `proposals` (or a fresh vector if not
provided).
"""
function self_search(agent::Agent, agents::Vector{Agent}, G::SimpleGraph,
                     broker_node::Int, params::ModelParams, rng::AbstractRNG,
                     d_i::Int, r::Float64;
                     ws::Union{SimWorkspace, Nothing} = nothing,
                     reserved_capacity::Union{Vector{Int}, Nothing} = nothing,
                     proposals::Union{Vector{ProposedMatch}, Nothing} = nothing)
    out = proposals === nothing ? ProposedMatch[] : proposals
    d_i <= 0 && return out

    K = params.K
    agent_id = agent.id
    N = length(agents)

    # Workspace buffers (allocated locally if none provided; preferred path
    # passes a ws reused across agents within a single period).
    if ws === nothing
        neighbor_ids = Int[]; neighbor_evals = Float64[]; neighbor_caps = Int[]
        stranger_ids = Int[]; stranger_evals = Float64[]; stranger_caps = Int[]
        eligible = Int[]; nbr_mask = fill(false, N + 1)
        stranger_sample = Int[]
        local_marked = Int[]
    else
        neighbor_ids = ws.neighbor_ids; empty!(neighbor_ids)
        neighbor_evals = ws.neighbor_evals; empty!(neighbor_evals)
        neighbor_caps = ws.neighbor_caps; empty!(neighbor_caps)
        stranger_ids = ws.stranger_ids; empty!(stranger_ids)
        stranger_evals = ws.stranger_evals; empty!(stranger_evals)
        stranger_caps = ws.stranger_caps; empty!(stranger_caps)
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
        cap = current_open_capacity(agents, nbr, K, reserved_capacity)
        cap <= 0 && continue
        mean_q = partner_mean(agent, nbr)
        if !isnan(mean_q)
            push!(neighbor_ids, nbr)
            push!(neighbor_evals, mean_q)
            push!(neighbor_caps, cap)
        end
    end

    # Strangers: sample from non-neighbors with capacity. Use bitset for O(1) check.
    if params.n_strangers > 0
        @inbounds for j in 1:N
            j == agent_id && continue
            nbr_mask[j] && continue
            current_open_capacity(agents, j, K, reserved_capacity) <= 0 && continue
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
                push!(stranger_caps, current_open_capacity(agents, j, K, reserved_capacity))
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
            neighbor_caps[idx] > 0 || continue
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
            stranger_caps[idx] > 0 || continue
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
        push!(out, ProposedMatch(agent_id, best_id, :self, best_eval, false, NaN, NaN))
        @inbounds for idx in eachindex(neighbor_ids)
            if neighbor_ids[idx] == best_id
                neighbor_caps[idx] -= 1
                @goto next_slot
            end
        end
        @inbounds for idx in eachindex(stranger_ids)
            if stranger_ids[idx] == best_id
                stranger_caps[idx] -= 1
                break
            end
        end
        @label next_slot
    end

    return out
end

"""
    append_self_round_preferences!(out, agent, agents, G, broker_node, params, rng, r; ws) -> Int

Append demander-side ranked self-search options for one within-period round.
Each feasible candidate appears at most once, ordered by the demander's current
evaluation (known-partner mean for neighbors, NN prediction for strangers).
Returns the number of appended preferences.
"""
function append_self_round_preferences!(out::Vector{ProposedMatch},
                                        agent::Agent,
                                        agents::Vector{Agent},
                                        G::SimpleGraph,
                                        broker_node::Int,
                                        params::ModelParams,
                                        rng::AbstractRNG,
                                        r::Float64;
                                        ws::Union{SimWorkspace, Nothing} = nothing,
                                        reserved_capacity::Union{Vector{Int}, Nothing} = nothing)::Int
    K = params.K
    agent_id = agent.id
    N = length(agents)

    if ws === nothing
        neighbor_ids = Int[]; neighbor_evals = Float64[]
        stranger_ids = Int[]; stranger_evals = Float64[]
        eligible = Int[]; nbr_mask = fill(false, N + 1)
        local_marked = Int[]
    else
        neighbor_ids = ws.neighbor_ids; empty!(neighbor_ids)
        neighbor_evals = ws.neighbor_evals; empty!(neighbor_evals)
        stranger_ids = ws.stranger_ids; empty!(stranger_ids)
        stranger_evals = ws.stranger_evals; empty!(stranger_evals)
        eligible = ws.eligible; empty!(eligible)
        if length(ws.nbr_mask) < N + 1
            old_len = length(ws.nbr_mask)
            resize!(ws.nbr_mask, N + 1)
            @inbounds for i in (old_len + 1):(N + 1)
                ws.nbr_mask[i] = false
            end
        end
        nbr_mask = ws.nbr_mask
        local_marked = ws.nbr_marked; empty!(local_marked)
    end

    @inbounds for nbr in neighbors(G, agent_id)
        nbr == broker_node && continue
        (nbr < 1 || nbr > N) && continue
        nbr_mask[nbr] = true
        push!(local_marked, nbr)
        current_open_capacity(agents, nbr, K, reserved_capacity) > 0 || continue
        mean_q = partner_mean(agent, nbr)
        if !isnan(mean_q) && mean_q > r
            push!(neighbor_ids, nbr)
            push!(neighbor_evals, mean_q)
        end
    end

    if params.n_strangers > 0
        @inbounds for j in 1:N
            j == agent_id && continue
            nbr_mask[j] && continue
            current_open_capacity(agents, j, K, reserved_capacity) > 0 || continue
            push!(eligible, j)
        end

        n_sample = min(params.n_strangers, length(eligible))
        if n_sample > 0
            sampled = sample(rng, eligible, n_sample; replace=false)
            @inbounds for j in sampled
                q_hat = predict_nn!(agent.nn, agent.predict_buf, agents[j].type)
                q_hat > r || continue
                push!(stranger_ids, j)
                push!(stranger_evals, q_hat)
            end
        end
    end

    @inbounds for nbr in local_marked
        nbr_mask[nbr] = false
    end

    start_idx = length(out) + 1
    @inbounds for idx in eachindex(neighbor_ids)
        push!(out, ProposedMatch(agent_id, neighbor_ids[idx], :self,
                                 neighbor_evals[idx], false, NaN, NaN))
    end
    @inbounds for idx in eachindex(stranger_ids)
        push!(out, ProposedMatch(agent_id, stranger_ids[idx], :self,
                                 stranger_evals[idx], false, NaN, NaN))
    end

    n_added = length(out) - start_idx + 1
    n_added <= 0 && return 0

    sort!(view(out, start_idx:length(out)); by=pm -> pm.evaluation, rev=true)
    return n_added
end

# ─────────────────────────────────────────────────────────────────────────────
# Broker allocation
# ─────────────────────────────────────────────────────────────────────────────

"""
    broker_allocate(broker, client_demands, agents, params, rng, r; ws, proposals)

Greedy best-pair allocation from the broker's quality matrix. Builds a batched
NN prediction over unique (demander, accessible counterparty) pairs, where the
broker's current access set is the standing roster plus current-period broker
clients. The allocator then iterates in descending quality order, allowing the
same demander-counterparty pair to fill multiple slots if it remains the best
feasible pair. Appends matches to `proposals` (or a fresh vector).
"""
function broker_allocate(broker::Broker, client_demands::Vector{Tuple{Int, Int}},
                         agents::Vector{Agent}, params::ModelParams,
                         rng::AbstractRNG, r::Float64;
                         ws::Union{SimWorkspace, Nothing} = nothing,
                         reserved_capacity::Union{Vector{Int}, Nothing} = nothing,
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
        access_seen = falses(N)
        access_touched = Int[]
    else
        roster_members = ws.roster_members; empty!(roster_members)
        roster_capacity = ws.roster_capacity; empty!(roster_capacity)
        unique_demanders = ws.unique_demanders; empty!(unique_demanders)
        demander_remaining = ws.demander_remaining; empty!(demander_remaining)
        demander_touched = ws.demander_touched; empty!(demander_touched)
        if length(ws.access_seen) < N
            old = length(ws.access_seen)
            resize!(ws.access_seen, N)
            @inbounds for i in (old+1):N
                ws.access_seen[i] = false
            end
        end
        access_seen = ws.access_seen
        access_touched = ws.access_touched; empty!(access_touched)
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

    # Available counterparties from the standing roster plus current-period clients.
    for rid in broker.roster
        (rid < 1 || rid > N) && continue
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        access_seen[rid] && continue
        access_seen[rid] = true
        push!(access_touched, rid)
        push!(roster_members, rid)
    end
    for rid in broker.current_clients
        (rid < 1 || rid > N) && continue
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        access_seen[rid] && continue
        access_seen[rid] = true
        push!(access_touched, rid)
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
        roster_capacity[ri] = current_open_capacity(agents, roster_members[ri], K, reserved_capacity)
    end

    # Iterate sorted entries. A selected pair can fill multiple slots because the
    # broker's within-period ranking is static and repeated same-counterparty
    # placements are allowed while both sides retain capacity.
    @inbounds for k in 1:n_entries
        neg_val, flat = sort_pairs[k]
        val = -neg_val
        val == -Inf && break
        val <= r && break

        di = (flat - 1) % n_unique + 1
        ri = (flat - 1) ÷ n_unique + 1

        n_alloc = min(demander_remaining[di], roster_capacity[ri])
        n_alloc <= 0 && continue

        for _ in 1:n_alloc
            push!(out, ProposedMatch(
                unique_demanders[di],
                roster_members[ri],
                :broker, val, false, NaN, NaN
            ))
        end

        demander_remaining[di] -= n_alloc
        roster_capacity[ri] -= n_alloc
    end

    @label cleanup
    # Sparse-clear demander_idx (only entries we touched)
    @inbounds for aid in demander_touched
        demander_idx[aid] = 0
    end
    @inbounds for aid in access_touched
        access_seen[aid] = false
    end

    return out
end

function prepare_broker_quality_matrix!(broker::Broker,
                                        demander_ids::Vector{Int},
                                        access_ids::Vector{Int},
                                        agents::Vector{Agent},
                                        params::ModelParams;
                                        ws::Union{SimWorkspace, Nothing} = nothing)
    isempty(demander_ids) &&
        return (Q=Matrix{Float64}(undef, 0, 0), roster_members=access_ids,
                sort_pairs=Tuple{Float64, Int}[], n_roster=0)
    isempty(access_ids) &&
        return (Q=Matrix{Float64}(undef, 0, 0), roster_members=access_ids,
                sort_pairs=Tuple{Float64, Int}[], n_roster=0)

    d = params.d
    d2 = 2 * d
    h_b = params.h_b
    n_unique = length(demander_ids)
    n_roster = length(access_ids)

    if ws !== nothing && (size(ws.Q, 1) < n_unique || size(ws.Q, 2) < n_roster)
        ws.Q = Matrix{Float64}(undef, max(n_unique, size(ws.Q, 1)),
                                      max(n_roster, size(ws.Q, 2)))
    end
    Q = ws === nothing ? Matrix{Float64}(undef, n_unique, n_roster) : ws.Q

    n_pairs = n_unique * n_roster
    n_self = 0
    @inbounds for ri in 1:n_roster
        rid = access_ids[ri]
        for di in 1:n_unique
            demander_ids[di] == rid && (n_self += 1)
        end
    end
    n_pairs -= n_self

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

    col = 0
    @inbounds for ri in 1:n_roster
        rid = access_ids[ri]
        xj = agents[rid].type
        for di in 1:n_unique
            did = demander_ids[di]
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

    n_pairs > 0 && predict_nn_batch!(broker.nn, H_batch, Y_batch, Z_batch, n_pairs)

    col = 0
    @inbounds for ri in 1:n_roster
        rid = access_ids[ri]
        for di in 1:n_unique
            if demander_ids[di] != rid
                col += 1
                Q[di, ri] = Y_batch[col]
            end
        end
    end

    sort_pairs = ws === nothing ? Tuple{Float64, Int}[] : ws.sort_pairs
    length(sort_pairs) < n_roster && resize!(sort_pairs, n_roster)
    ws !== nothing && (ws.sort_pairs = sort_pairs)

    return (Q=Q, roster_members=access_ids, sort_pairs=sort_pairs, n_roster=n_roster)
end

"""
    prepare_broker_round_matrix!(broker, demander_ids, agents, params; ws)

Build the broker's current-round quality matrix over `demander_ids` and the
current broker access set `A^t`. Returns a NamedTuple with the precomputed
matrix, the access-set agent IDs, reusable sort scratch, and the realized
access-set size.
"""
function prepare_broker_round_matrix!(broker::Broker,
                                      demander_ids::Vector{Int},
                                      agents::Vector{Agent},
                                      params::ModelParams;
                                      ws::Union{SimWorkspace, Nothing} = nothing,
                                      reserved_capacity::Union{Vector{Int}, Nothing} = nothing)
    isempty(demander_ids) &&
        return (Q=Matrix{Float64}(undef, 0, 0), roster_members=Int[],
                sort_pairs=Tuple{Float64, Int}[], n_roster=0)

    K = params.K
    N = length(agents)

    if ws === nothing
        roster_members = Int[]
        access_seen = falses(N)
        access_touched = Int[]
        sort_pairs = Tuple{Float64, Int}[]
    else
        roster_members = ws.roster_members; empty!(roster_members)
        if length(ws.access_seen) < N
            old = length(ws.access_seen)
            resize!(ws.access_seen, N)
            @inbounds for i in (old + 1):N
                ws.access_seen[i] = false
            end
        end
        access_seen = ws.access_seen
        access_touched = ws.access_touched; empty!(access_touched)
        sort_pairs = ws.sort_pairs
    end

    for rid in broker.roster
        (rid < 1 || rid > N) && continue
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        access_seen[rid] && continue
        access_seen[rid] = true
        push!(access_touched, rid)
        push!(roster_members, rid)
    end
    for rid in broker.current_clients
        (rid < 1 || rid > N) && continue
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        access_seen[rid] && continue
        access_seen[rid] = true
        push!(access_touched, rid)
        push!(roster_members, rid)
    end
    n_roster = length(roster_members)
    if n_roster == 0
        @inbounds for aid in access_touched
            access_seen[aid] = false
        end
        empty_Q = ws === nothing ? Matrix{Float64}(undef, 0, 0) : ws.Q
        return (Q=empty_Q, roster_members=roster_members,
                sort_pairs=sort_pairs, n_roster=0)
    end

    @inbounds for aid in access_touched
        access_seen[aid] = false
    end

    return prepare_broker_quality_matrix!(broker, demander_ids, roster_members, agents, params; ws=ws)
end

"""
    prepare_period_broker_round_cache!(broker, demand_agent_ids, demand_channels,
                                       agents, params; ws, reserved_capacity=nothing)

Build the broker's within-period quality cache once, over all demanders that
chose the broker channel and the post-planning access set that is open at the
start of round matching. Later rounds reuse this matrix and only re-filter the
currently open counterparties.
"""
function prepare_period_broker_round_cache!(broker::Broker,
                                            demand_agent_ids::Vector{Int},
                                            demand_channels::Vector{Symbol},
                                            agents::Vector{Agent},
                                            params::ModelParams;
                                            ws::Union{SimWorkspace, Nothing} = nothing,
                                            reserved_capacity::Union{Vector{Int}, Nothing} = nothing)
    ws === nothing && return nothing

    period_demanders = ws.period_broker_demanders; empty!(period_demanders)
    @inbounds for idx in eachindex(demand_agent_ids)
        demand_channels[idx] == :broker || continue
        push!(period_demanders, demand_agent_ids[idx])
    end

    period_access_ids = ws.period_broker_access_ids; empty!(period_access_ids)
    isempty(period_demanders) && return nothing

    K = params.K
    N = length(agents)
    if length(ws.access_seen) < N
        old = length(ws.access_seen)
        resize!(ws.access_seen, N)
        @inbounds for i in (old + 1):N
            ws.access_seen[i] = false
        end
    end
    access_seen = ws.access_seen
    access_touched = ws.access_touched; empty!(access_touched)

    @inbounds for rid in broker.roster
        (rid < 1 || rid > N) && continue
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        access_seen[rid] && continue
        access_seen[rid] = true
        push!(access_touched, rid)
        push!(period_access_ids, rid)
    end
    @inbounds for rid in broker.current_clients
        (rid < 1 || rid > N) && continue
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        access_seen[rid] && continue
        access_seen[rid] = true
        push!(access_touched, rid)
        push!(period_access_ids, rid)
    end

    @inbounds for rid in access_touched
        access_seen[rid] = false
    end
    isempty(period_access_ids) && return nothing

    prepare_broker_quality_matrix!(broker, period_demanders, period_access_ids, agents, params; ws=ws)
    return nothing
end

"""
    append_broker_round_preferences_from_matrix!(out, counts, broker_matrix, demander_ids,
                                                 agents, params, r; demander_slots=nothing)

Append demander-side ranked broker options from a precomputed broker quality
matrix. When `demander_slots` is provided, demanders with zero remaining slots
contribute no preferences.
"""
function append_broker_round_preferences_from_matrix!(out::Vector{ProposedMatch},
                                                      counts::Vector{Int},
                                                      broker_matrix,
                                                      demander_ids::Vector{Int},
                                                      agents::Vector{Agent},
                                                      params::ModelParams,
                                                      r::Float64;
                                                      demander_slots::Union{Vector{Int}, Nothing} = nothing,
                                                      reserved_capacity::Union{Vector{Int}, Nothing} = nothing)
    empty!(out)
    resize!(counts, length(demander_ids))
    fill!(counts, 0)
    isempty(demander_ids) && return out

    K = params.K
    Q = broker_matrix.Q
    roster_members = broker_matrix.roster_members
    sort_pairs = broker_matrix.sort_pairs
    n_roster = broker_matrix.n_roster
    n_roster == 0 && return out

    @inbounds for di in eachindex(demander_ids)
        !isnothing(demander_slots) && demander_slots[di] <= 0 && continue
        did = demander_ids[di]
        for ri in 1:n_roster
            sort_pairs[ri] = (-Q[di, ri], ri)
        end
        sort!(view(sort_pairs, 1:n_roster), alg=QuickSort)

        for k in 1:n_roster
            neg_val, ri = sort_pairs[k]
            val = -neg_val
            val <= r && break
            rid = roster_members[ri]
            did == rid && continue
            current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
            push!(out, ProposedMatch(did, rid, :broker, val, false, NaN, NaN))
            counts[di] += 1
        end
    end

    return out
end

"""
    append_broker_round_preferences_from_cache!(out, counts, demander_ids, agents,
                                                params, r; ws, demander_slots=nothing)

Append demander-side ranked broker options using the period-level broker
quality cache prepared once before round matching. Only currently open
counterparties are considered in each round, preserving the live-capacity
logic while avoiding repeated broker NN passes.
"""
function append_broker_round_preferences_from_cache!(out::Vector{ProposedMatch},
                                                     counts::Vector{Int},
                                                     demander_ids::Vector{Int},
                                                     agents::Vector{Agent},
                                                     params::ModelParams,
                                                     r::Float64;
                                                     ws::Union{SimWorkspace, Nothing} = nothing,
                                                     demander_slots::Union{Vector{Int}, Nothing} = nothing,
                                                     reserved_capacity::Union{Vector{Int}, Nothing} = nothing)
    ws === nothing &&
        error("append_broker_round_preferences_from_cache! requires a workspace cache")

    empty!(out)
    resize!(counts, length(demander_ids))
    fill!(counts, 0)
    isempty(demander_ids) && return out

    period_demanders = ws.period_broker_demanders
    period_access_ids = ws.period_broker_access_ids
    isempty(period_demanders) && return out
    isempty(period_access_ids) && return out

    K = params.K
    Q = ws.Q
    sort_pairs = ws.sort_pairs
    open_cols = ws.period_broker_open_cols; empty!(open_cols)

    @inbounds for col in eachindex(period_access_ids)
        rid = period_access_ids[col]
        current_open_capacity(agents, rid, K, reserved_capacity) > 0 || continue
        push!(open_cols, col)
    end
    isempty(open_cols) && return out

    length(sort_pairs) < length(open_cols) && resize!(sort_pairs, length(open_cols))

    row_cursor = 1
    @inbounds for di in eachindex(demander_ids)
        !isnothing(demander_slots) && demander_slots[di] <= 0 && continue
        did = demander_ids[di]
        while row_cursor <= length(period_demanders) && period_demanders[row_cursor] != did
            row_cursor += 1
        end
        row_cursor > length(period_demanders) &&
            error("Broker round cache desynchronized from current demander order")

        for k in eachindex(open_cols)
            col = open_cols[k]
            sort_pairs[k] = (-Q[row_cursor, col], col)
        end
        sort!(view(sort_pairs, 1:length(open_cols)), alg=QuickSort)

        for k in 1:length(open_cols)
            neg_val, col = sort_pairs[k]
            val = -neg_val
            val <= r && break
            rid = period_access_ids[col]
            did == rid && continue
            push!(out, ProposedMatch(did, rid, :broker, val, false, NaN, NaN))
            counts[di] += 1
        end
    end

    return out
end

"""
    build_broker_round_preferences!(out, counts, broker, demander_ids, agents, params, r; ws) -> Vector

Build demander-side ranked broker options for one within-period round. The
output vector is grouped by `demander_ids` order, and `counts[k]` records the
number of appended preferences for demander `demander_ids[k]`.
"""
function build_broker_round_preferences!(out::Vector{ProposedMatch},
                                         counts::Vector{Int},
                                         broker::Broker,
                                         demander_ids::Vector{Int},
                                         agents::Vector{Agent},
                                         params::ModelParams,
                                         r::Float64;
                                         ws::Union{SimWorkspace, Nothing} = nothing,
                                         reserved_capacity::Union{Vector{Int}, Nothing} = nothing)
    broker_matrix = prepare_broker_round_matrix!(broker, demander_ids, agents, params;
                                                 ws=ws, reserved_capacity=reserved_capacity)
    append_broker_round_preferences_from_matrix!(out, counts, broker_matrix,
                                                 demander_ids, agents, params, r;
                                                 reserved_capacity=reserved_capacity)
    return out
end
