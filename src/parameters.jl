"""
    parameters.jl

Default parameter construction and validation for the Transient Brokerage ABM.
"""

"""
    default_params(; seed=42, kwargs...)::ModelParams

Construct a `ModelParams` with baseline defaults, overriding any field via keyword arguments.
"""
function default_params(; seed::Int = 42, kwargs...)::ModelParams
    defaults = Dict{Symbol,Any}(
        :d => 8,
        :s => 2,
        :rho => 0.50,
        :K_mu => 10,
        :N_W => 1000,
        :N_F => 100,
        :eta => 0.05,
        :beta_W => 0.50,
        :k_nn => 10,
        :k_S => 6,
        :p_rewire => 0.1,
        :omega => 0.3,
        :alpha => 0.20,
        :L => 4,
        :mu_b => 0.25,
        :c_emp_frac => 0.15,
        :p_vac => 0.20,
        :pool_target_frac => 0.20,
        :n_candidates_frac => 0.01,
        :network_measure_interval => 10,
        :T => 200,
        :T_burn => 20,
        :seed => seed,
    )
    for (k, v) in kwargs
        haskey(defaults, k) || error("Unknown parameter: $k")
        defaults[k] = v
    end
    p = ModelParams(
        defaults[:d],
        defaults[:s],
        defaults[:rho],
        defaults[:K_mu],
        defaults[:N_W],
        defaults[:N_F],
        defaults[:eta],
        defaults[:beta_W],
        defaults[:k_nn],
        defaults[:k_S],
        defaults[:p_rewire],
        defaults[:omega],
        defaults[:alpha],
        defaults[:L],
        defaults[:mu_b],
        defaults[:c_emp_frac],
        defaults[:p_vac],
        defaults[:pool_target_frac],
        defaults[:n_candidates_frac],
        defaults[:network_measure_interval],
        defaults[:T],
        defaults[:T_burn],
        defaults[:seed],
    )
    validate_params(p)
    return p
end

"""
    validate_params(p::ModelParams)

Assert that all parameter values satisfy model constraints. Throws on violation.
"""
function validate_params(p::ModelParams)
    @assert p.s >= 1 "s must be ≥ 1, got $(p.s)"
    @assert p.d >= 2 * p.s "d must be ≥ 2s (P⊥U constraint), got d=$(p.d), s=$(p.s)"
    @assert 0.0 <= p.rho <= 1.0 "rho must be in [0, 1], got $(p.rho)"
    @assert p.K_mu >= 1 "K_mu must be ≥ 1, got $(p.K_mu)"
    @assert p.N_W >= 1 "N_W must be ≥ 1, got $(p.N_W)"
    @assert p.N_F >= 1 "N_F must be ≥ 1, got $(p.N_F)"
    @assert 0.0 < p.eta < 1.0 "eta must be in (0, 1), got $(p.eta)"
    @assert 0.0 < p.beta_W < 1.0 "beta_W must be in (0, 1), got $(p.beta_W)"
    @assert p.k_nn >= 1 "k_nn must be ≥ 1, got $(p.k_nn)"
    @assert p.k_S >= 2 "k_S must be ≥ 2 (even degree for Watts-Strogatz), got $(p.k_S)"
    @assert iseven(p.k_S) "k_S must be even for Watts-Strogatz, got $(p.k_S)"
    @assert 0.0 <= p.p_rewire <= 1.0 "p_rewire must be in [0, 1], got $(p.p_rewire)"
    @assert 0.0 < p.omega < 1.0 "omega must be in (0, 1), got $(p.omega)"
    @assert 0.0 < p.alpha <= 1.0 "alpha must be in (0, 1], got $(p.alpha)"
    @assert p.L >= 1 "L must be ≥ 1, got $(p.L)"
    @assert 0.0 < p.mu_b < 1.0 "mu_b must be in (0, 1), got $(p.mu_b)"
    @assert 0.0 < p.c_emp_frac < 1.0 "c_emp_frac must be in (0, 1), got $(p.c_emp_frac)"
    @assert 0.0 < p.p_vac <= 1.0 "p_vac must be in (0, 1], got $(p.p_vac)"
    @assert 0.0 < p.pool_target_frac <= 1.0 "pool_target_frac must be in (0, 1], got $(p.pool_target_frac)"
    @assert 0.0 < p.n_candidates_frac <= 1.0 "n_candidates_frac must be in (0, 1], got $(p.n_candidates_frac)"
    @assert p.network_measure_interval >= 1 "network_measure_interval must be ≥ 1, got $(p.network_measure_interval)"
    @assert p.T >= 1 "T must be ≥ 1, got $(p.T)"
    @assert p.T_burn >= 0 "T_burn must be ≥ 0, got $(p.T_burn)"
    @assert p.T_burn < p.T "T_burn must be < T, got T_burn=$(p.T_burn), T=$(p.T)"
    return nothing
end
