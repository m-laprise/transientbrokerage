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
    generate_firm_geometry(mode, d, N_F, rng) -> FirmGeometry

Create firm geometry parameters for the given mode:
- :complex — sinusoidal curve spanning all d dimensions (d-ref frequency scaling)
- :simple — great circle between two random unit vectors
- :unstructured — anisotropic Gaussian blob, normalized to unit sphere
"""
function generate_firm_geometry(mode::Symbol, d::Int, N_F::Int, rng::AbstractRNG)::FirmGeometry
    empty_d = Float64[]
    empty_dd = zeros(0, 0)

    if mode == :complex
        freq_scale = sqrt(8 / d)  # d_ref = 8
        freqs = (1.0 .+ 2.0 .* rand(rng, d)) .* freq_scale
        phases = 2π .* rand(rng, d)
        return FirmGeometry(mode, freqs, phases,
                            empty_d, empty_d, 0.0,
                            empty_d, empty_dd, empty_d)
    elseif mode == :simple
        a = randn(rng, d); a ./= norm(a)
        b = randn(rng, d); b ./= norm(b)
        # Orthogonalize b from a, then set angle to achieve target adj spacing
        b .-= dot(b, a) .* a; b ./= norm(b)
        # Target: adj ≈ 0.28 for N_F=50. With slerp, adj = 2*sin(θ/(2*(N_F-1))).
        # For adj=0.28: θ = 2*(N_F-1)*arcsin(0.14) ≈ 98*0.1405 ≈ 13.8.
        # This wraps around the great circle ~2.2 times — use modular slerp.
        theta = 2.0 * (N_F - 1) * asin(0.14)
        return FirmGeometry(mode, empty_d, empty_d,
                            a, b, theta,
                            empty_d, empty_dd, empty_d)
    elseif mode == :unstructured
        # Anisotropic Gaussian: random center, random rotation, calibrated scales
        center = randn(rng, d); center ./= norm(center)
        # Random orthonormal basis via QR
        axes = Matrix(qr(randn(rng, d, d)).Q)
        # Strongly anisotropic scales: first dimension ~10× last, so the blob
        # is elongated like an ellipsoid. After sphere projection, nearby firms
        # along the major axis are close, firms across the minor axes are far.
        raw_scales = [1.0 / k^0.8 for k in 1:d]  # power-law: ~6:1 ratio
        raw_scales .*= 1.0 / raw_scales[1]  # largest scale = 1.0 (wide spread before projection)
        return FirmGeometry(mode, empty_d, empty_d,
                            empty_d, empty_d, 0.0,
                            center, axes, raw_scales)
    else
        error("Unknown firm geometry: $mode")
    end
end

"""
    sample_firm_type(geo, t, d, rng) -> Vector{Float64}

Sample a firm type. Meaning of `t` depends on the geometry:
- :complex — position on sinusoidal curve (deterministic given t)
- :simple — position on great circle (deterministic given t)
- :unstructured — ignored; draws a fresh random point from the blob
"""
function sample_firm_type(geo::FirmGeometry, t::Float64, d::Int, rng::AbstractRNG)::Vector{Float64}
    if geo.mode == :complex
        x = [sin(2π * geo.freqs[k] * t + geo.phases[k]) for k in 1:d]
        x ./= norm(x)
        return x
    elseif geo.mode == :simple
        # Great circle parameterized by angle: x(t) = cos(φ)·a + sin(φ)·b
        φ = t * geo.arc_theta
        x = cos(φ) .* geo.arc_a .+ sin(φ) .* geo.arc_b
        x ./= norm(x)
        return x
    elseif geo.mode == :unstructured
        z = geo.axes * (geo.scales .* randn(rng, d))
        x = geo.center .+ z
        x ./= norm(x)
        return x
    else
        error("Unknown firm geometry: $(geo.mode)")
    end
end

"""
    generate_firm_types(geo, N_F, d, rng) -> Vector{Vector{Float64}}

N_F firm types from the geometry. For structured modes (:complex, :simple),
firms are evenly spaced along the curve. For :unstructured, N_F random draws.
"""
function generate_firm_types(geo::FirmGeometry, N_F::Int, d::Int, rng::AbstractRNG)::Vector{Vector{Float64}}
    if geo.mode == :unstructured
        return [sample_firm_type(geo, 0.0, d, rng) for _ in 1:N_F]
    else
        return [sample_firm_type(geo, t, d, rng) for t in range(0.0, 1.0; length=N_F)]
    end
end

"""
    create_firm(id, type, d) -> Firm

Create a new firm with the given type vector and preallocated history arrays.
"""
function create_firm(id::Int, type::Vector{Float64}, d::Int)::Firm
    Firm(id=id, type=type,
         history_w=Matrix{Float64}(undef, d, 200),
         history_q=Vector{Float64}(undef, 200),
         history_count=0)
end

"""Convenience: create a firm with a random type drawn from N(0,I)."""
function create_firm(id::Int, d::Int, rng::AbstractRNG)::Firm
    create_firm(id, randn(rng, d), d)
end

"""
    create_broker(id, params, workers, rng) -> Broker

Create the broker with a pool of P = ceil(pool_target_frac * N_W) available workers
and preallocated history arrays.
"""
function create_broker(id::Int, params::ModelParams, workers::Vector{Worker},
                       rng::AbstractRNG)::Broker
    P = ceil(Int, params.pool_target_frac * params.N_W)
    available_ids = [w.id for w in workers if w.status == available]
    seed_pool = Set(sample(rng, available_ids, min(P, length(available_ids)); replace=false))
    cap = 10_000
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
    assign_initial_employment!(firms, workers, env, rng)

Assign 6-10 workers per firm, sampling by type proximity (softmax weighting).
Workers are drawn without replacement from the available pool. Each hire's
match output is realized and recorded to the firm's history, seeding the
firm's prediction model.
"""
function assign_initial_employment!(firms::Vector{Firm}, workers::Vector{Worker},
                                    env::MatchingEnv, rng::AbstractRNG)
    N_W = length(workers)
    avail = trues(N_W)
    candidates = Vector{Int}(undef, N_W)
    wts = Vector{Float64}(undef, N_W)
    for firm in firms
        n_initial = rand(rng, 6:10)
        nc = 0
        @inbounds for wid in 1:N_W
            if avail[wid]
                nc += 1
                candidates[nc] = wid
            end
        end
        n_hire = min(n_initial, nc)
        chosen = sample_by_proximity(rng, candidates, nc, workers, firm.type, wts, n_hire)
        for wid in chosen
            workers[wid].status = employed
            workers[wid].employer_id = firm.id
            push!(firm.employees, wid)
            avail[wid] = false
            # Record realized output to firm history
            q = match_output(workers[wid].type, firm.type, env, rng)
            record_history!(firm, workers[wid].type, q)
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

    # 1. Firm geometry and types (needed before matching function for ideal worker draw)
    firm_geo = generate_firm_geometry(params.firm_geometry, d, params.N_F, rng)
    firm_type_vecs = generate_firm_types(firm_geo, params.N_F, d, rng)

    # 2. Matching function (ideal worker c drawn from firm types)
    env = generate_matching_function(d, params.rho,
                                     firm_type_vecs, rng; sigma_w=params.sigma_w)

    # 3. Calibration constants using actual firm types
    f_mean, r_base = calibrate_output_scale(env, firm_type_vecs, rng; sigma_w=params.sigma_w)
    q_pub = f_mean
    cal = CalibrationConstants(r_base, f_mean, q_pub)

    # 4. Worker types: each worker is a perturbation of a random firm's type
    #    sigma_w controls dispersion around the firm curve.
    #    Per-dimension scale is sigma_w / sqrt(d) so that the expected Euclidean
    #    distance from the reference firm ≈ sigma_w regardless of d.
    #    Sorted by PC1 for network construction.
    σ_per_dim = params.sigma_w / sqrt(d)
    X = Matrix{Float64}(undef, d, params.N_W)
    for i in 1:params.N_W
        ref = firm_type_vecs[rand(rng, 1:params.N_F)]
        @views X[:, i] .= ref .+ σ_per_dim .* randn(rng, d)
    end
    pc1_scores = vec(predict(fit(PCA, X; maxoutdim=1), X))
    sort_order = sortperm(pc1_scores)
    worker_types = [X[:, i] for i in sort_order]

    # 5. Social network — node i corresponds to worker_types[i] (PC1-sorted),
    #    so ring-lattice neighbors in the Watts-Strogatz graph are type-proximal
    G_S = build_social_network(params.N_W, params.k_S, params.p_rewire, rng)

    # 6. Reservation wages (compute degree vector once)
    degs = degree(G_S)
    max_deg = maximum(degs)
    reservation_wages = [compute_reservation_wage(degs[i], max_deg, r_base, rng)
                         for i in 1:params.N_W]

    # 7. Workers (id == node_id invariant: worker IDs are used as G_S node indices)
    workers = [Worker(id=i, node_id=i, type=worker_types[i],
                      reservation_wage=reservation_wages[i])
               for i in 1:params.N_W]
    @assert all(w.id == w.node_id for w in workers) "Worker id must equal node_id"

    # 8. Firms (using pre-drawn types)
    firms = [create_firm(j, firm_type_vecs[j], d) for j in 1:params.N_F]

    # 9. Initial employment (with history seeding)
    assign_initial_employment!(firms, workers, env, rng)

    # 10. Broker with seed pool and seeded history from 20 random existing matches
    broker = create_broker(1, params, workers, rng)
    employed_pairs = [(wid, j) for (j, firm) in enumerate(firms) for wid in firm.employees]
    seed_pairs = sample(rng, employed_pairs, min(20, length(employed_pairs)); replace=false)
    for (wid, j) in seed_pairs
        q = match_output(workers[wid].type, firms[j].type, env, rng)
        record_broker_history!(broker, workers[wid].type, firms[j].type, j, q)
    end

    # 11. Initialize satisfaction at q_pub
    for firm in firms
        firm.satisfaction_internal = q_pub
        firm.satisfaction_broker = q_pub
    end

    # 12. Broker reputation at q_pub
    broker.last_reputation = q_pub

    # 13. Referral pools (after employment assigned)
    compute_all_referral_pools!(firms, workers, G_S)

    # 14. Accumulators and cached network measures
    accum = PeriodAccumulators()
    cached_network = CachedNetworkMeasures(NaN, NaN, NaN)

    return ModelState(params=params, rng=rng, period=0, env=env, cal=cal,
                      firm_geo=firm_geo,
                      workers=workers, firms=firms, broker=broker, G_S=G_S,
                      open_vacancies=Set{Int}(), next_firm_id=params.N_F + 1,
                      accum=accum, cached_network=cached_network)
end
