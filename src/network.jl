"""
    network.jl

Single undirected network G with N+1 nodes (N agents + 1 broker).
Edges form from matches; the broker is a permanent node connected to all standing
roster members, current broker clients, and agents currently engaged in
broker-channel matches.
"""

using Graphs: SimpleGraph, watts_strogatz, add_edge!, neighbors, nv, rem_edge!, has_edge
using Random: AbstractRNG

"""
    build_network(N, k, p_rewire, rng) -> SimpleGraph{Int}

Build a Watts-Strogatz small-world graph with N+1 nodes (N agents + 1 broker node).
Agent nodes are 1:N; broker node is N+1 (initially unconnected).
The `rng` is used to extract a seed for the Watts-Strogatz construction.
"""
function build_network(N::Int, k::Int, p_rewire::Float64, rng::AbstractRNG)::SimpleGraph{Int}
    seed = rand(rng, 1:typemax(Int32))
    # Build WS graph for N agent nodes
    G = watts_strogatz(N, k, p_rewire; seed=seed)
    # Add broker node (N+1), initially with no edges
    add_vertex!(G)
    return G
end

"""
    add_match_edge!(G, i, j)

Add an undirected edge between agents i and j in G, if not already present.
This is the sole mechanism of network densification.
"""
function add_match_edge!(G::SimpleGraph, i::Int, j::Int)
    if !has_edge(G, i, j)
        add_edge!(G, i, j)
    end
    return nothing
end

"""
    add_broker_edge!(G, agent_id, broker_node)

Connect an agent to the broker node.
"""
function add_broker_edge!(G::SimpleGraph, agent_id::Int, broker_node::Int)
    if !has_edge(G, agent_id, broker_node)
        add_edge!(G, agent_id, broker_node)
    end
    return nothing
end

"""
    sync_broker_edges!(G, agents, broker) -> Nothing

Synchronize broker-node edges to match the standing roster, current broker
clients, and agents currently engaged in broker-channel matches. This keeps the
broker's structural reach aligned with the maintained roster while also
representing the current broker client base and active brokered relationships in
the period graph.
"""
function sync_broker_edges!(G::SimpleGraph, agents::Vector{Agent}, broker::Broker)
    broker_node = broker.node_id
    N = length(agents)

    @inbounds for i in 1:N
        should_connect = (i in broker.roster) ||
                         (i in broker.current_clients) ||
                         has_active_broker_match(agents[i])
        if should_connect
            has_edge(G, i, broker_node) || add_edge!(G, i, broker_node)
        else
            has_edge(G, i, broker_node) && rem_edge!(G, i, broker_node)
        end
    end

    return nothing
end

"""
    broker_access_size(broker) -> Int

Return the size of the broker's current hybrid access set, defined as the union
of the standing roster and current-period broker clients.
"""
function broker_access_size(broker::Broker)::Int
    n_access = length(broker.roster)
    for agent_id in broker.current_clients
        agent_id in broker.roster && continue
        n_access += 1
    end
    return n_access
end

"""
    remove_agent_edges!(G, agent_id)

Remove all edges incident to agent_id. Used on agent exit before reusing the node.
"""
function remove_agent_edges!(G::SimpleGraph, agent_id::Int)
    # Collect neighbors first to avoid modifying while iterating
    nbrs = collect(neighbors(G, agent_id))
    for nbr in nbrs
        rem_edge!(G, agent_id, nbr)
    end
    return nothing
end

"""
    add_entrant_edges!(G, agent_id, agent_type, agents, rng; n_edges)

Connect a new entrant to `n_edges` existing agents sampled by type proximity.
Probability of connecting to agent j is proportional to exp(-||x_new - x_j||²).
"""
function add_entrant_edges!(G::SimpleGraph, agent_id::Int, agent_type::Vector{Float64},
                            agents::Vector{Agent}, rng::AbstractRNG;
                            n_edges::Int)
    N = length(agents)
    n_edges = min(n_edges, N - 1)
    n_edges <= 0 && return nothing

    # Compute weights: exp(-||x_new - x_j||²) for all agents except self
    weights = Vector{Float64}(undef, N)
    total_weight = 0.0
    @inbounds for j in 1:N
        if j == agent_id
            weights[j] = 0.0
        else
            diff_sq = 0.0
            xj = agents[j].type
            @simd for k in eachindex(agent_type)
                diff_sq += (agent_type[k] - xj[k])^2
            end
            w = exp(-diff_sq)
            weights[j] = w
            total_weight += w
        end
    end

    # Sample n_edges agents without replacement (weighted)
    total_weight <= 0.0 && return nothing
    selected = Set{Int}()
    for _ in 1:n_edges
        r = rand(rng) * total_weight
        cumulative = 0.0
        chosen = 0
        @inbounds for j in 1:N
            cumulative += weights[j]
            if cumulative >= r
                chosen = j
                break
            end
        end
        chosen == 0 && continue
        if chosen ∉ selected
            push!(selected, chosen)
            add_edge!(G, agent_id, chosen)
            # Remove from future sampling
            total_weight -= weights[chosen]
            weights[chosen] = 0.0
        end
    end
    return nothing
end
