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

"""
    add_coworker_ties!(G_S, worker_id, firm_employees, rng)

Add G_S ties between a newly hired worker and a random half of their coworkers
(up to 5 new ties). Called on direct hires and placements, not staffing.
Uses partial Fisher-Yates shuffle — one allocation for the coworker list.
"""
function add_coworker_ties!(G_S::SimpleGraph, worker_id::Int,
                            firm_employees::Set{Int}, rng::AbstractRNG)
    coworkers = Int[]
    for wid in firm_employees
        wid != worker_id && push!(coworkers, wid)
    end
    nc = length(coworkers)
    nc == 0 && return nothing
    n_ties = min(cld(nc, 2), 5)
    for i in 1:n_ties
        j = rand(rng, i:nc)
        coworkers[i], coworkers[j] = coworkers[j], coworkers[i]
        add_edge!(G_S, worker_id, coworkers[i])
    end
    return nothing
end

"""
    add_all_coworker_ties!(G_S, employee_ids)

Connect all members of a group pairwise in G_S. Used for initial employees
at firm creation (initialization and entry). Deterministic — no RNG consumed.
"""
function add_all_coworker_ties!(G_S::SimpleGraph, employee_ids)
    ids = collect(employee_ids)
    for i in 1:length(ids), j in (i+1):length(ids)
        add_edge!(G_S, ids[i], ids[j])
    end
    return nothing
end
