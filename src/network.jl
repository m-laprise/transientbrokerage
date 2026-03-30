"""
    network.jl

Social network construction and referral pool computation.
"""

"""
    build_social_network(N_W, k_S, p_rewire, rng) -> SimpleGraph{Int}

Build a Watts-Strogatz small-world graph with `N_W` nodes, degree `k_S`,
and rewiring probability `p_rewire`.
"""
function build_social_network(N_W::Int, k_S::Int, p_rewire::Float64,
                               rng::AbstractRNG)::SimpleGraph{Int}
    seed = rand(rng, 1:typemax(Int32))
    return watts_strogatz(N_W, k_S, p_rewire; seed=seed)
end

"""
    compute_referral_pool!(firm, workers, G_S)

Set firm's referral pool to the social neighbors of current employees,
excluding employees themselves. Worker IDs are used as graph node indices
(worker.id == worker.node_id, enforced at initialization).
"""
function compute_referral_pool!(firm::Firm, workers::Vector{Worker},
                                 G_S::SimpleGraph)
    empty!(firm.referral_pool)
    for emp_id in firm.employees
        for nbr_id in neighbors(G_S, emp_id)
            if nbr_id ∉ firm.employees
                push!(firm.referral_pool, nbr_id)
            end
        end
    end
    return nothing
end

"""
    compute_all_referral_pools!(firms, workers, G_S)

Recompute referral pools for all firms.
"""
function compute_all_referral_pools!(firms::Vector{Firm}, workers::Vector{Worker},
                                     G_S::SimpleGraph)
    for firm in firms
        compute_referral_pool!(firm, workers, G_S)
    end
    return nothing
end
