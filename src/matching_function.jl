"""
    matching_function.jl

Matching function f(w, x) = mu(w) + w'x + noise: generation, evaluation, and calibration.
"""

"""Squared Euclidean distance between column `j` of matrix `M` and vector `z`."""
@inline function _col_sqdist(M::Matrix{Float64}, j::Int, z::AbstractVector, d::Int)
    d2 = 0.0
    @inbounds for k in 1:d
        δ = z[k] - M[k, j]
        d2 += δ * δ
    end
    return d2
end

"""
    generate_matching_function(d, rho, K_mu, rng) -> MatchingEnv

Build the RBF-based general quality function mu(w) on the full d-dimensional type
space, with variance calibrated so Var(mu)/Var(f) = rho. The interaction is w'x
(identity, full rank). No projection or rank reduction.
"""
function generate_matching_function(d::Int, rho::Float64,
                                     K_mu::Int, rng::AbstractRNG)
    # RBF centers (d × K_mu, columns) and non-negative raw weights (squared for mu >= 0)
    mu_centers = randn(rng, d, K_mu)
    mu_weights_raw = randn(rng, K_mu) .^ 2

    # MC worker samples for bandwidth and variance calibration
    n_cal = 10_000
    w_samples = Matrix{Float64}(undef, d, n_cal)
    for i in 1:n_cal
        @views randn!(rng, w_samples[:, i])
        @views clamp!(w_samples[:, i], -3.0, 3.0)
    end

    # Bandwidth = median pairwise distance (subsample for speed)
    n_pair = min(500, n_cal)
    pairwise_dists = Vector{Float64}(undef, n_pair * (n_pair - 1) ÷ 2)
    idx = 0
    for i in 1:n_pair, j in (i+1):n_pair
        idx += 1
        @inbounds pairwise_dists[idx] = sqrt(_col_sqdist(w_samples, i, view(w_samples, :, j), d))
    end
    mu_bandwidth = median(pairwise_dists)

    # Scale weights so Var(mu)/Var(f) = rho
    if rho > 0.0
        inv2h2 = 1.0 / (2.0 * mu_bandwidth^2)
        mu_vals = Vector{Float64}(undef, n_cal)
        for i in 1:n_cal
            val = 0.0
            @inbounds for l in 1:K_mu
                val += mu_weights_raw[l] * exp(-_col_sqdist(mu_centers, l, view(w_samples, :, i), d) * inv2h2)
            end
            mu_vals[i] = val
        end
        var_mu = var(mu_vals)

        x_buf = Vector{Float64}(undef, d)
        interaction_vals = Vector{Float64}(undef, n_cal)
        for i in 1:n_cal
            randn!(rng, x_buf); clamp!(x_buf, -3.0, 3.0)
            interaction_vals[i] = dot(view(w_samples, :, i), x_buf)
        end
        scale = sqrt(rho / (1.0 - rho) * var(interaction_vals) / max(var_mu, 1e-12))
        mu_weights = mu_weights_raw .* scale
    else
        mu_weights = zeros(K_mu)
    end

    return MatchingEnv(d, mu_centers, mu_weights, mu_bandwidth)
end

"""
    eval_mu(w, env) -> Float64

Non-negative general worker quality mu(w) = sum_l a_l * exp(- ||w - c_l||^2 / 2h^2),
where all a_l >= 0. Operates directly on the full d-dimensional worker type.
"""
function eval_mu(w::AbstractVector, env::MatchingEnv)::Float64
    inv2h2 = 1.0 / (2.0 * env.mu_bandwidth^2)
    centers = env.mu_centers
    weights = env.mu_weights
    d = env.d
    val = 0.0
    @inbounds for l in eachindex(weights)
        val += weights[l] * exp(-_col_sqdist(centers, l, w, d) * inv2h2)
    end
    return val
end

"""
    match_output(w, x, env, rng) -> Float64

Stochastic match output f(w,x) = mu(w) + w'x + eps, where eps ~ N(0,1).
"""
function match_output(w::AbstractVector, x::AbstractVector,
                      env::MatchingEnv, rng::AbstractRNG)::Float64
    return eval_mu(w, env) + dot(w, x) + randn(rng)
end

"""
    match_output_noiseless(w, x, env) -> Float64

Deterministic match output mu(w) + w'x, without noise.
Used by `calibrate_output_scale` to estimate E[f].
"""
function match_output_noiseless(w::AbstractVector, x::AbstractVector,
                                 env::MatchingEnv)::Float64
    return eval_mu(w, env) + dot(w, x)
end

"""
    calibrate_output_scale(env, firm_types, rng; n_samples=10_000) -> (f_mean, r_base)

Monte Carlo calibration using clustered worker-firm pairs (worker = firm_type + N(0,I),
matching the initialization distribution). Returns:
- f_mean = E[f] (mean output, used for q_pub and f_bar)
- r_base = 0.60 * f_mean (reservation wage floor)
"""
function calibrate_output_scale(env::MatchingEnv,
                          firm_types::Vector{Vector{Float64}},
                          rng::AbstractRNG;
                          n_samples::Int = 10_000)::Tuple{Float64,Float64}
    d = env.d
    n_firms = length(firm_types)
    w = Vector{Float64}(undef, d)
    total = 0.0
    for _ in 1:n_samples
        x = firm_types[rand(rng, 1:n_firms)]
        for k in 1:d
            w[k] = clamp(x[k] + randn(rng), -3.0, 3.0)
        end
        total += match_output_noiseless(w, x, env)
    end
    f_mean = total / n_samples
    return (f_mean, 0.60 * f_mean)
end
