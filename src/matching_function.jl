"""
    matching_function.jl

Matching function f(w, x) = ρ·tanh(cos(w,c)) + (1-ρ)·cos(w,x) + ε.
Both components are cosine-normalized so ρ directly controls the mixing weight.
The ideal worker c is drawn like an (N_W+1)th worker.
"""

"""
    generate_matching_function(d, rho, firm_types, rng; sigma_w=0.5) -> MatchingEnv

Build the matching environment. The ideal worker c is drawn as a perturbation
of a random firm type (sigma_w / sqrt(d) per dimension, like a real worker).
"""
function generate_matching_function(d::Int, rho::Float64,
                                     firm_types::Vector{Vector{Float64}},
                                     rng::AbstractRNG; sigma_w::Float64=0.5)
    σ_per_dim = sigma_w / sqrt(d)
    ref = firm_types[rand(rng, 1:length(firm_types))]
    c = clamp.(ref .+ σ_per_dim .* randn(rng, d), -3.0, 3.0)
    c_norm = norm(c)
    return MatchingEnv(d, rho, c, c_norm)
end

"""Cosine similarity w'x / (‖w‖‖x‖), or 0 if either vector is near-zero."""
function cosine_sim(w::AbstractVector, x::AbstractVector)::Float64
    w_norm = norm(w)
    x_norm = norm(x)
    (w_norm < 1e-12 || x_norm < 1e-12) && return 0.0
    return dot(w, x) / (w_norm * x_norm)
end

"""
    eval_mu(w, env) -> Float64

General worker quality: tanh(cos(w, c)).
Returns the raw (unweighted) quality; the ρ mixing happens in match_output.
"""
eval_mu(w::AbstractVector, env::MatchingEnv)::Float64 = tanh(cosine_sim(w, env.c))

"""
    eval_interaction(w, x) -> Float64

Match-specific interaction: cos(w, x) (cosine similarity).
"""
eval_interaction(w::AbstractVector, x::AbstractVector)::Float64 = cosine_sim(w, x)

"""Noise standard deviation for match output."""
const SIGMA_EPS = 0.25

"""Offset ensuring match output is positive for well-matched pairs."""
const Q_OFFSET = 1.0

"""
    match_output(w, x, env, rng) -> Float64

Stochastic match output q = Q_OFFSET + ρ·tanh(cos(w,c)) + (1-ρ)·cos(w,x) + ε.
The offset shifts the signal from [-1,1] to [0,2], ensuring positive output
for typical matches. ε ~ N(0, σ_ε²) with σ_ε = $(SIGMA_EPS).
"""
function match_output(w::AbstractVector, x::AbstractVector,
                      env::MatchingEnv, rng::AbstractRNG)::Float64
    return Q_OFFSET + env.rho * eval_mu(w, env) + (1.0 - env.rho) * eval_interaction(w, x) + SIGMA_EPS * randn(rng)
end

"""
    match_output_noiseless(w, x, env) -> Float64

Deterministic match output Q_OFFSET + ρ·tanh(cos(w,c)) + (1-ρ)·cos(w,x).
"""
function match_output_noiseless(w::AbstractVector, x::AbstractVector,
                                 env::MatchingEnv)::Float64
    return Q_OFFSET + env.rho * eval_mu(w, env) + (1.0 - env.rho) * eval_interaction(w, x)
end

"""
    calibrate_output_scale(env, firm_types, rng; sigma_w=0.5, n_samples=10_000) -> (f_mean, r_base)

Monte Carlo calibration using random worker-firm pairs from the full population.
Workers are drawn as perturbations of random firm types, then evaluated against
*independently* drawn firms — matching the distribution firms actually face when
searching. Returns:
- f_mean = E[f] (mean output across random pairs, used for q_pub)
- r_base = 0.60 * f_mean (reservation wage floor)
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
        # Worker drawn near a random reference firm
        ref = firm_types[rand(rng, 1:n_firms)]
        for k in 1:d
            w[k] = clamp(ref[k] + σ_per_dim * randn(rng), -3.0, 3.0)
        end
        # Evaluated against an independently drawn firm (not the reference)
        x = firm_types[rand(rng, 1:n_firms)]
        total += match_output_noiseless(w, x, env)
    end
    f_mean = total / n_samples
    return (f_mean, 0.70 * f_mean)
end
