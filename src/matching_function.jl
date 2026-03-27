"""
    matching_function.jl

Matching function f(w, x) = mu(w) + w'Ax + noise: generation, evaluation, and calibration.
"""

"""Squared Euclidean distance between column `j` of matrix `M` and vector `z`."""
@inline function _col_sqdist(M::Matrix{Float64}, j::Int, z::AbstractVector, s::Int)
    d2 = 0.0
    @inbounds for k in 1:s
        δ = z[k] - M[k, j]
        d2 += δ * δ
    end
    return d2
end

"""
    generate_matching_function(d, s, rho, K_mu, rng) -> MatchingEnv

Build a diagonal rank-s interaction matrix A, orthogonal projection P, and
RBF-based general quality function mu with variance calibrated so
Var(mu)/Var(f) = rho. A = I_d[:,1:s] * I_d[:,1:s]' so the interaction
reduces to w[1:s]'x[1:s] (first s dimensions interact directly).
"""
function generate_matching_function(d::Int, s::Int, rho::Float64,
                                     K_mu::Int, rng::AbstractRNG)
    # Interaction matrix A: diagonal, rank s.
    # U = V = first s coordinate axes, so A[i,i] = 1 for i <= s, 0 elsewhere.
    U = zeros(d, s)
    for i in 1:s; U[i, i] = 1.0; end
    A = U * U'

    # Projection P ∈ R^{s×d}, rows orthonormal and ⊥ colspan(U)
    P_raw = randn(rng, s, d)
    @views for i in 1:s
        P_raw[i, :] .-= U * (U' * P_raw[i, :])
    end
    P = Matrix(qr(P_raw').Q)'[1:s, :]
    @assert norm(P * U) < 1e-10 "P must be orthogonal to U"

    # RBF centers (s × K_mu, columns) and non-negative raw weights (squared for mu >= 0)
    mu_centers = randn(rng, s, K_mu)
    mu_weights_raw = randn(rng, K_mu) .^ 2

    # Project MC worker samples for bandwidth and variance calibration
    n_cal = 10_000
    w_buf = Vector{Float64}(undef, d)
    projected = Matrix{Float64}(undef, s, n_cal)
    for i in 1:n_cal
        randn!(rng, w_buf)
        clamp!(w_buf, -3.0, 3.0)
        @views mul!(projected[:, i], P, w_buf)
    end

    # Bandwidth = median pairwise distance (subsample for speed)
    n_pair = min(500, n_cal)
    pairwise_dists = Vector{Float64}(undef, n_pair * (n_pair - 1) ÷ 2)
    idx = 0
    for i in 1:n_pair, j in (i+1):n_pair
        idx += 1
        @inbounds pairwise_dists[idx] = sqrt(_col_sqdist(projected, i, view(projected, :, j), s))
    end
    mu_bandwidth = median(pairwise_dists)

    # Scale weights so Var(mu)/Var(f) = rho
    if rho > 0.0
        inv2h2 = 1.0 / (2.0 * mu_bandwidth^2)
        mu_vals = Vector{Float64}(undef, n_cal)
        for i in 1:n_cal
            val = 0.0
            @inbounds for l in 1:K_mu
                val += mu_weights_raw[l] * exp(-_col_sqdist(mu_centers, l, view(projected, :, i), s) * inv2h2)
            end
            mu_vals[i] = val
        end
        var_mu = var(mu_vals)

        x_buf = Vector{Float64}(undef, d)
        Ax_buf = Vector{Float64}(undef, d)
        interaction_vals = Vector{Float64}(undef, n_cal)
        for i in 1:n_cal
            randn!(rng, w_buf); clamp!(w_buf, -3.0, 3.0)
            randn!(rng, x_buf); clamp!(x_buf, -3.0, 3.0)
            mul!(Ax_buf, A, x_buf)
            interaction_vals[i] = dot(w_buf, Ax_buf)
        end
        scale = sqrt(rho / (1.0 - rho) * var(interaction_vals) / max(var_mu, 1e-12))
        mu_weights = mu_weights_raw .* scale
    else
        mu_weights = zeros(K_mu)
    end

    return MatchingEnv(A, U, P, mu_centers, mu_weights, mu_bandwidth)
end

"""
    eval_mu!(z, w, env) -> Float64

Non-negative general worker quality mu(w) = sum_l a_l * exp(- ||Pw - c_l||^2 / 2h^2),
where all a_l >= 0. Writes the projection Pw into `z` (pre-allocated s-vector).
"""
function eval_mu!(z::AbstractVector, w::AbstractVector, env::MatchingEnv)::Float64
    mul!(z, env.P, w)
    inv2h2 = 1.0 / (2.0 * env.mu_bandwidth^2)
    centers = env.mu_centers
    weights = env.mu_weights
    s = length(z)
    val = 0.0
    @inbounds for l in eachindex(weights)
        val += weights[l] * exp(-_col_sqdist(centers, l, z, s) * inv2h2)
    end
    return val
end

"""
    match_output!(z, Ax, w, x, env, rng) -> Float64

Stochastic match output f(w,x) = mu(w) + w'Ax + eps, where eps ~ N(0,1).
Writes into `z` (s-vector) and `Ax` (d-vector).
"""
function match_output!(z::AbstractVector, Ax::AbstractVector,
                       w::AbstractVector, x::AbstractVector,
                       env::MatchingEnv, rng::AbstractRNG)::Float64
    mu_val = eval_mu!(z, w, env)
    mul!(Ax, env.A, x)
    return mu_val + dot(w, Ax) + randn(rng)
end

"""
    match_output_noiseless!(z, Ax, w, x, env) -> Float64

Deterministic match output mu(w) + w'Ax, without noise.
Used by `calibrate_output_scale` to compute E[f] and E[|f|] from Monte Carlo
samples without noise contamination. Writes into `z` (s-vector) and `Ax` (d-vector).
"""
function match_output_noiseless!(z::AbstractVector, Ax::AbstractVector,
                                  w::AbstractVector, x::AbstractVector,
                                  env::MatchingEnv)::Float64
    mu_val = eval_mu!(z, w, env)
    mul!(Ax, env.A, x)
    return mu_val + dot(w, Ax)
end

"""
    calibrate_output_scale(env, d, firm_types, rng; n_samples=10_000) -> (f_bar, f_mean, r_base)

Monte Carlo calibration using clustered worker-firm pairs. Workers are drawn as
perturbations of randomly selected firm types (sigma_w = 1.0), matching the
initialization distribution. Returns:
- f_bar = E[|f|] (output magnitude, used for r_base)
- f_mean = E[f] (mean output, used for q_pub)
- r_base = 0.70 * f_bar (reservation wage floor)
"""
function calibrate_output_scale(env::MatchingEnv, d::Int,
                          firm_types::Vector{Vector{Float64}},
                          rng::AbstractRNG;
                          n_samples::Int = 10_000)::Tuple{Float64,Float64,Float64}
    s = size(env.P, 1)
    n_firms = length(firm_types)
    w = Vector{Float64}(undef, d)
    z, Ax = Vector{Float64}(undef, s), Vector{Float64}(undef, d)
    total_abs = 0.0
    total_raw = 0.0
    for _ in 1:n_samples
        x = firm_types[rand(rng, 1:n_firms)]
        for k in 1:d
            w[k] = clamp(x[k] + randn(rng), -3.0, 3.0)
        end
        val = match_output_noiseless!(z, Ax, w, x, env)
        total_abs += abs(val)
        total_raw += val
    end
    f_bar = total_abs / n_samples
    f_mean = total_raw / n_samples
    return (f_bar, f_mean, 0.70 * f_bar)
end
