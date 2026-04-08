"""
    matching_function.jl

Matching function f(w, x) = ρ·sim(w,c) + (1-ρ)·sim(w, Ax).
Quality is cosine similarity with an ideal worker c.
Interaction is cosine similarity between w and the transformed firm type Ax,
where A is a random d×d matrix drawn at initialization.

Observable match output is q = Q + f(w,x) + ε, where Q is a constant offset
that shifts q positive for downstream economic computations (wages, surplus).
Q is deliberately excluded from f so that f represents the pure signal structure
of the DGP (important for SVD analysis and examining structural complexity).
"""

"""
    generate_matching_function(d, rho, firm_types, rng; sigma_w=0.5) -> MatchingEnv

Build the matching environment. The ideal worker c is drawn as a perturbation
of a random firm type. The interaction matrix A has iid N(0,1) entries, creating
cross-dimensional interactions that make the matching problem harder for firms
to learn from local data alone.
"""
function generate_matching_function(d::Int, rho::Float64,
                                     firm_types::Vector{Vector{Float64}},
                                     rng::AbstractRNG;
                                     sigma_w::Float64=0.5, sigma_eps::Float64=0.25)
    σ_per_dim = sigma_w / sqrt(d)
    ref = firm_types[rand(rng, 1:length(firm_types))]
    c = ref .+ σ_per_dim .* randn(rng, d)
    c_norm = norm(c)
    A = randn(rng, d, d)
    return MatchingEnv(d, rho, c, c_norm, A, sigma_eps)
end

"""Cosine similarity a'b / (‖a‖‖b‖), or 0 if either vector is near-zero."""
function cosine_sim(a::AbstractVector, b::AbstractVector)::Float64
    a_norm = norm(a)
    b_norm = norm(b)
    (a_norm < 1e-12 || b_norm < 1e-12) && return 0.0
    return dot(a, b) / (a_norm * b_norm)
end

"""
    eval_mu(w, env) -> Float64

General worker quality: sim(w, c) (cosine similarity with ideal worker).
"""
eval_mu(w::AbstractVector, env::MatchingEnv)::Float64 = cosine_sim(w, env.c)

"""
    eval_interaction(w, x, env) -> Float64

Match-specific interaction: sim(w, Ax) (cosine similarity between w and the
transformed firm type Ax). The matrix A introduces cross-dimensional interactions.
"""
function eval_interaction(w::AbstractVector, x::AbstractVector, env::MatchingEnv)::Float64
    return cosine_sim(w, env.A * x)
end

"""In-place version using pre-allocated buffer for Ax."""
function eval_interaction!(Ax_buf::Vector{Float64}, w::AbstractVector, x::AbstractVector, env::MatchingEnv)::Float64
    mul!(Ax_buf, env.A, x)
    return cosine_sim(w, Ax_buf)
end

"""Noise standard deviation for match output."""
const SIGMA_EPS = 0.25

"""Offset added to f(w,x) in the observable output q = Q + f(w,x) + ε.
Shifts q positive for downstream economic computations; not part of the
matching function f itself (excluded from match_signal)."""
const Q_OFFSET = 1.0

"""Reservation wage as fraction of mean match output: r_base = R_BASE_FRAC × f̄."""
const R_BASE_FRAC = 0.70

"""
    match_output(w, x, env, rng) -> Float64

Stochastic observable match output q = Q + f(w,x) + ε, where
f(w,x) = ρ·sim(w,c) + (1-ρ)·sim(w, Ax) is the deterministic signal
(see `match_signal`), Q = Q_OFFSET shifts q positive for downstream
economic computations, and ε ~ N(0, σ_ε²) is match noise.
"""
function match_output(w::AbstractVector, x::AbstractVector,
                      env::MatchingEnv, rng::AbstractRNG)::Float64
    return Q_OFFSET + env.rho * eval_mu(w, env) + (1.0 - env.rho) * eval_interaction(w, x, env) + env.sigma_eps * randn(rng)
end

"""
    match_signal(w, x, env) -> Float64

Deterministic matching function f(w,x) = ρ·sim(w,c) + (1-ρ)·sim(w, Ax).
Does not include the offset Q or noise ε. Used for diagnostics, holdout
evaluation, and SVD analysis where the pure signal structure matters.
"""
function match_signal(w::AbstractVector, x::AbstractVector,
                      env::MatchingEnv)::Float64
    return env.rho * eval_mu(w, env) + (1.0 - env.rho) * eval_interaction(w, x, env)
end

"""In-place version of `match_signal` using pre-allocated Ax buffer."""
function match_signal!(Ax_buf::Vector{Float64}, w::AbstractVector,
                       x::AbstractVector, env::MatchingEnv)::Float64
    return env.rho * eval_mu(w, env) + (1.0 - env.rho) * eval_interaction!(Ax_buf, w, x, env)
end

"""
    calibrate_output_scale(env, firm_types, rng; sigma_w=0.5, n_samples=10_000) -> (f_mean, r_base)

Monte Carlo calibration of E[q] = E[Q + f(w,x)] using random worker-firm pairs.
Returns (mean_q, r_base) where r_base = R_BASE_FRAC × mean_q.
"""
function calibrate_output_scale(env::MatchingEnv,
                          firm_types::Vector{Vector{Float64}},
                          rng::AbstractRNG;
                          sigma_w::Float64 = 0.5,
                          n_samples::Int = 10_000)::Tuple{Float64,Float64}
    d = env.d
    σ_per_dim = sigma_w / sqrt(d)
    n_firms = length(firm_types)
    w = Vector{Float64}(undef, d)
    total = 0.0
    for _ in 1:n_samples
        ref = firm_types[rand(rng, 1:n_firms)]
        for k in 1:d
            w[k] = ref[k] + σ_per_dim * randn(rng)
        end
        x = firm_types[rand(rng, 1:n_firms)]
        total += Q_OFFSET + match_signal(w, x, env)
    end
    f_mean = total / n_samples
    return (f_mean, R_BASE_FRAC * f_mean)
end
