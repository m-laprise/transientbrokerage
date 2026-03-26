"""
    initialization.jl

Model initialization: agents, network, reservation wages, and initial employment.
"""

"""
    compute_reservation_wage(deg, max_deg, r_base, rng; network_premium=0.20, noise_scale=0.05) -> Float64

Reservation wage with degree-based network premium and noise, floored at `r_base`.
Better-connected workers have higher outside options (spec 3b).
"""
function compute_reservation_wage(deg::Int, max_deg::Int, r_base::Float64,
                                  rng::AbstractRNG;
                                  network_premium::Float64 = 0.20,
                                  noise_scale::Float64 = 0.05)::Float64
    raw = r_base * (1.0 + network_premium * deg / max_deg) + noise_scale * r_base * randn(rng)
    return max(r_base, raw)
end

"""
    create_firm(id, d, rng) -> Firm

Create a new firm with a random type and preallocated history arrays.
"""
function create_firm(id::Int, d::Int, rng::AbstractRNG)::Firm
    x = randn(rng, d)
    clamp!(x, -3.0, 3.0)
    Firm(id=id, type=x,
         history_w=Matrix{Float64}(undef, d, 200),
         history_q=Vector{Float64}(undef, 200),
         history_count=0)
end

"""
    create_broker(id, params, workers, rng) -> Broker

Create the broker with a seed pool of ceil(0.02 * N_W) available workers
and preallocated history arrays.
"""
function create_broker(id::Int, params::ModelParams, workers::Vector{Worker},
                       rng::AbstractRNG)::Broker
    n_seed = ceil(Int, 0.02 * params.N_W)
    available_ids = [w.id for w in workers if w.status == available]
    seed_pool = Set(sample(rng, available_ids, min(n_seed, length(available_ids)); replace=false))
    cap = 5000
    Broker(id=id,
           pool=seed_pool,
           history_w=Matrix{Float64}(undef, params.d, cap),
           history_x=Matrix{Float64}(undef, params.d, cap),
           history_q=Vector{Float64}(undef, cap),
           history_firm_idx=Vector{Int}(undef, cap),
           history_count=0)
end

"""
    sample_by_proximity(rng, candidates, nc, workers, firm_type, wts, n_hire) -> Vector{Int}

Draw `n_hire` workers from `candidates[1:nc]` with probability proportional to
exp(-||w_i - x_j||^2). Both `candidates` and `wts` are caller-owned buffers;
`wts` is resized to `nc` internally.
"""
function sample_by_proximity(rng::AbstractRNG, candidates::Vector{Int}, nc::Int,
                             workers::Vector{Worker}, firm_type::Vector{Float64},
                             wts::Vector{Float64}, n_hire::Int)::Vector{Int}
    resize!(wts, nc)
    total = 0.0
    @inbounds for (i, wid) in enumerate(@view(candidates[1:nc]))
        d2 = 0.0
        wtype = workers[wid].type
        for k in eachindex(wtype)
            δ = wtype[k] - firm_type[k]
            d2 += δ * δ
        end
        v = exp(-d2)
        wts[i] = v
        total += v
    end
    @views wts[1:nc] ./= total
    return sample(rng, @view(candidates[1:nc]), Weights(@view(wts[1:nc])),
                  n_hire; replace=false)
end

"""
    assign_initial_employment!(firms, workers, rng)

Assign 3-5 workers per firm, sampling by type proximity (softmax weighting).
Workers are drawn without replacement from the available pool.
"""
function assign_initial_employment!(firms::Vector{Firm}, workers::Vector{Worker},
                                    rng::AbstractRNG)
    avail = Set(1:length(workers))
    candidates = collect(avail)
    wts = Vector{Float64}(undef, length(workers))
    for firm in firms
        n_initial = rand(rng, 3:5)
        resize!(candidates, length(avail))
        copyto!(candidates, avail)
        nc = length(candidates)
        n_hire = min(n_initial, nc)
        chosen = sample_by_proximity(rng, candidates, nc, workers, firm.type, wts, n_hire)
        for wid in chosen
            workers[wid].status = employed
            workers[wid].employer_id = firm.id
            push!(firm.employees, wid)
            delete!(avail, wid)
        end
    end
    return nothing
end

"""
    initialize_model(params) -> ModelState

Build the complete initial model state: matching function, agents, network,
reservation wages, initial employment, and broker pool.
"""
function initialize_model(params::ModelParams)::ModelState
    rng = StableRNG(params.seed)
    d = params.d

    # 1. Matching function
    env = generate_matching_function(d, params.s, params.rho, params.K_mu, rng)

    # 2. Calibration constants
    f_bar, r_base = calibrate_output_scale(env, d, rng)
    q_pub = f_bar
    cal = CalibrationConstants(r_base, f_bar, q_pub)

    # 3. Worker types sorted by PC1 for network construction
    X = Matrix{Float64}(undef, d, params.N_W)
    for i in 1:params.N_W
        @views randn!(rng, X[:, i])
        @views clamp!(X[:, i], -3.0, 3.0)
    end
    pc1_scores = vec(predict(fit(PCA, X; maxoutdim=1), X))
    sort_order = sortperm(pc1_scores)
    worker_types = [X[:, i] for i in sort_order]

    # 4. Social network — node i corresponds to worker_types[i] (PC1-sorted),
    #    so ring-lattice neighbors in the Watts-Strogatz graph are type-proximal
    G_S = build_social_network(params.N_W, params.k_S, params.p_rewire, rng)

    # 5. Reservation wages (compute degree vector once)
    degs = degree(G_S)
    max_deg = maximum(degs)
    reservation_wages = [compute_reservation_wage(degs[i], max_deg, r_base, rng)
                         for i in 1:params.N_W]

    # 6. Workers
    workers = [Worker(id=i, node_id=i, type=worker_types[i],
                      reservation_wage=reservation_wages[i])
               for i in 1:params.N_W]

    # 7. Firms
    firms = [create_firm(j, d, rng) for j in 1:params.N_F]

    # 8. Initial employment
    assign_initial_employment!(firms, workers, rng)

    # 9. Broker with seed pool
    broker = create_broker(1, params, workers, rng)

    # 10. Initialize satisfaction at q_pub
    for firm in firms
        firm.satisfaction_internal = q_pub
        firm.satisfaction_broker = q_pub
    end

    # 11. Broker reputation at q_pub
    broker.last_reputation = q_pub

    # 12. Referral pools (after employment assigned)
    compute_all_referral_pools!(firms, workers, G_S)

    # 13. Accumulators and cached network measures
    accum = PeriodAccumulators()
    cached_network = CachedNetworkMeasures(NaN, NaN, NaN)

    return ModelState(params=params, rng=rng, period=0, env=env, cal=cal,
                      workers=workers, firms=firms, broker=broker, G_S=G_S,
                      open_vacancies=Set{Int}(), next_firm_id=params.N_F + 1,
                      accum=accum, cached_network=cached_network)
end
