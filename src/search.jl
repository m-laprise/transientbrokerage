"""
    search.jl

Internal search and broker greedy allocation.
"""

"""
    internal_search(firm, workers, available, params, rng, model) -> (worker_id, q_hat_firm)

Draw candidates from referral pool and general pool (§5a), evaluate via firm ridge model,
return the best candidate with positive surplus. Returns `(0, 0.0)` if none found.
"""
function internal_search(firm::Firm,
                         workers::Vector{Worker},
                         available::Set{Int},
                         params::ModelParams,
                         rng::AbstractRNG,
                         model::RidgeModel)::Tuple{Int, Float64}
    n = ceil(Int, params.n_candidates_frac * params.N_W)
    half_n = n ÷ 2

    # Partition available workers into referral and general pools
    # Use sizehint! to avoid repeated resizing
    referral_buf = sizehint!(Int[], min(length(firm.referral_pool), length(available)))
    general_buf = sizehint!(Int[], length(available))
    for w in available
        if w in firm.referral_pool
            push!(referral_buf, w)
        else
            push!(general_buf, w)
        end
    end

    # Draw floor(n/2) from referral, remainder from general (§5a)
    n_referral = min(half_n, length(referral_buf))
    n_general = min(n - n_referral, length(general_buf))
    candidates = sizehint!(Int[], n_referral + n_general)
    if n_referral > 0
        append!(candidates, sample(rng, referral_buf, n_referral; replace=false))
    end
    if n_general > 0
        append!(candidates, sample(rng, general_buf, n_general; replace=false))
    end
    isempty(candidates) && return (0, 0.0)

    # Evaluate via firm ridge model
    d = length(firm.type)
    buf = Vector{Float64}(undef, 2d)
    best_id = 0
    best_q = -Inf
    n_tied = 0
    for wid in candidates
        q_hat = predict_ridge!(model, buf, workers[wid].type)
        if q_hat > best_q
            best_q = q_hat
            best_id = wid
            n_tied = 1
        elseif q_hat == best_q
            n_tied += 1
            if rand(rng) < 1.0 / n_tied
                best_id = wid
            end
        end
    end

    # Surplus check
    if best_q <= workers[best_id].reservation_wage
        return (0, 0.0)
    end
    return (best_id, best_q)
end

"""
    broker_allocate!(broker, clients, workers, available_pool, params, rng, models) -> Vector{Tuple{Int, Int, Float64}}

Greedy best-pair allocation (§5b). Returns (firm_idx, worker_id, q_hat_broker) tuples.
"""
function broker_allocate!(broker::Broker,
                          clients::Vector{Tuple{Int, Firm}},
                          workers::Vector{Worker},
                          available_pool::Set{Int},
                          params::ModelParams,
                          rng::AbstractRNG,
                          models::PeriodModels)::Vector{Tuple{Int, Int, Float64}}
    pool = collect(intersect(broker.pool, available_pool))
    (isempty(pool) || isempty(clients)) && return Tuple{Int, Int, Float64}[]

    n_w = length(pool)
    n_c = length(clients)
    broker_model = models.broker_model
    d = length(workers[pool[1]].type)
    n_bf = broker_feature_dim(d)
    buf = Vector{Float64}(undef, n_bf)

    # Build quality matrix Q[worker_idx, client_idx]
    Q = Matrix{Float64}(undef, n_w, n_c)
    for (ci, (_, firm)) in enumerate(clients)
        for (wi, wid) in enumerate(pool)
            Q[wi, ci] = predict_ridge!(broker_model, buf, workers[wid].type, firm.type)
        end
    end

    # Greedy best-pair with tie-breaking
    assignments = Tuple{Int, Int, Float64}[]
    used_w = falses(n_w)
    used_c = falses(n_c)

    for _ in 1:min(n_w, n_c)
        best_val = -Inf
        n_tied = 0
        best_wi = 0
        best_ci = 0
        for ci in 1:n_c
            used_c[ci] && continue
            for wi in 1:n_w
                used_w[wi] && continue
                v = Q[wi, ci]
                if v > best_val
                    best_val = v
                    best_wi = wi
                    best_ci = ci
                    n_tied = 1
                elseif v == best_val
                    n_tied += 1
                    if rand(rng) < 1.0 / n_tied
                        best_wi = wi
                        best_ci = ci
                    end
                end
            end
        end
        best_val == -Inf && break

        wid = pool[best_wi]
        best_val <= workers[wid].reservation_wage && break

        j, _ = clients[best_ci]
        push!(assignments, (j, wid, best_val))
        used_w[best_wi] = true
        used_c[best_ci] = true
    end

    return assignments
end
