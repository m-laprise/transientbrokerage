"""
    entry_exit.jl

Agent entry and exit. Exiting agents are replaced by entrants with fresh types,
empty histories, and floor(k/2) edges to type-similar neighbors.
"""

using Random: AbstractRNG
using LinearAlgebra: norm

"""
    exit_agent!(state, agent_id)

Remove agent from the simulation: clear all edges in G, terminate active matches
(counterparties regain capacity), remove from broker roster.
The agent's node index is reused for the entrant.
"""
function exit_agent!(state::ModelState, agent_id::Int)
    agent = state.agents[agent_id]

    # Terminate all active matches: remove from partner's active list
    for am in agent.active_matches
        partner = state.agents[am.partner_id]
        idx = findfirst(m -> m.partner_id == agent_id, partner.active_matches)
        if idx !== nothing
            deleteat!(partner.active_matches, idx)
        end
    end
    empty!(agent.active_matches)

    # Remove all edges from G
    remove_agent_edges!(state.G, agent_id)

    # Remove from broker roster
    if agent.on_roster
        delete!(state.broker.roster, agent_id)
        agent.on_roster = false
    end

    return nothing
end

"""
    enter_agent!(state, agent_id, rng)

Replace an exited agent with a fresh entrant at the same node index.
New type from curve + noise, empty history, satisfaction at q_pub,
floor(k/2) edges to type-similar neighbors.
"""
function enter_agent!(state::ModelState, agent_id::Int, rng::AbstractRNG)
    p = state.params
    d = p.d
    geo = state.curve_geo

    # Generate fresh type on curve + noise
    cp = curve_point(rand(rng), geo)
    sigma_per_dim = p.sigma_x / sqrt(d)
    new_type = cp .+ sigma_per_dim .* randn(rng, d)
    new_type_norm = norm(new_type)
    if new_type_norm > 1e-12
        new_type ./= new_type_norm
    end

    agent = state.agents[agent_id]

    # Reset all fields
    agent.type .= new_type
    empty!(agent.active_matches)
    agent.history_count = 0
    agent.n_new_obs = 0

    # Re-initialize neural network
    agent.nn = init_neural_net(d, p.h_a, rng)
    agent.nn_grad = NNGradBuffers(agent.nn)
    fill!(agent.predict_buf, 0.0)

    # Reset partner tracking
    fill!(agent.partner_sum, 0.0)
    fill!(agent.partner_count, 0)

    # Reset satisfaction
    agent.satisfaction_self = state.cal.q_pub
    agent.satisfaction_broker = state.cal.q_pub
    agent.tried_broker = false
    agent.on_roster = false
    agent.periods_alive = 0

    # Add edges to type-similar neighbors
    n_edges = p.k ÷ 2
    add_entrant_edges!(state.G, agent_id, new_type, state.agents, rng;
                       n_edges=n_edges)

    return nothing
end

"""
    process_entry_exit!(state, rng)

Process agent turnover: each agent exits with probability η, immediately replaced.
"""
function process_entry_exit!(state::ModelState, rng::AbstractRNG)
    eta = state.params.eta
    eta <= 0.0 && return nothing

    for i in 1:state.params.N
        if rand(rng) < eta
            exit_agent!(state, i)
            enter_agent!(state, i, rng)
        end
    end

    return nothing
end
