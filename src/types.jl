"""
    types.jl

Agent types, model state, and supporting structs for the Transient Brokerage ABM.
"""

"""Available, directly employed by a firm, or staffed through the broker."""
@enum WorkerStatus available employed staffed

"""Labor market participant with a fixed skill type and reservation wage."""
Base.@kwdef mutable struct Worker
    id::Int
    node_id::Int                  # position in G_S (invariant across replacements)
    type::Vector{Float64}         # w_i ∈ R^d
    reservation_wage::Float64     # r_i, set at init, fixed
    status::WorkerStatus = available
    employer_id::Int = 0          # firm id if employed, 0 if available
    broker_id::Int = 0            # broker id if staffed, 0 otherwise
    staffing_firm_id::Int = 0     # firm where staffed, 0 if not staffed
end

"""Employer with vacancies, a k-NN hiring history, and channel satisfaction scores."""
Base.@kwdef mutable struct Firm
    id::Int
    type::Vector{Float64}                    # x_j ∈ R^d
    employees::Set{Int} = Set{Int}()         # worker IDs
    history_w::Matrix{Float64}               # d × capacity, columns are worker types
    history_q::Vector{Float64} = Float64[]   # realized outputs from direct hires
    history_count::Int = 0                   # total writes (may exceed capacity; use effective_history_size)
    satisfaction_internal::Float64 = 0.0
    satisfaction_broker::Float64 = 0.0
    tried_internal::Bool = false
    tried_broker::Bool = false
    referral_pool::Set{Int} = Set{Int}()     # R_j^t, recomputed each period
    hire_count::Int = 0                      # total direct hires made
    periods_alive::Int = 0
end

"""A broker-mediated staffing contract with fixed duration and locked bill rate."""
mutable struct StaffingAssignment
    worker_id::Int
    firm_id::Int
    broker_id::Int
    periods_remaining::Int
    worker_type::Vector{Float64}
    firm_type::Vector{Float64}
    bill_rate::Float64              # locked at assignment start (§9c)
    realized_q::Float64             # output drawn once at formation, repeated each period (§9g step 3.3.1)
    predicted_q::Float64            # broker's prediction q̂_b, used for per-period profit
end

"""A proposed hire with both predictions and computed wage, used for conflict resolution and finalization."""
struct ProposedMatch
    firm_idx::Int           # index into state.firms (not firm.id)
    worker_id::Int
    source::Symbol          # :internal or :broker
    q_hat_firm::Float64     # firm's prediction (used for wage, §3.1.1)
    q_hat_broker::Float64   # broker's prediction (drives allocation; 0.0 for internal)
    wage::Float64           # computed before conflict resolution (§3.1)
end

"""Single intermediary with a worker pool, cross-firm history, and sticky reputation."""
Base.@kwdef mutable struct Broker
    id::Int
    pool::Set{Int} = Set{Int}()              # worker IDs
    history_w::Matrix{Float64}               # d × capacity, columns are worker types
    history_x::Matrix{Float64}               # d × capacity, columns are firm types
    history_q::Vector{Float64} = Float64[]   # realized outputs
    history_firm_idx::Vector{Int} = Int[]    # which firm each observation came from (for Stage 2)
    history_count::Int = 0
    active_assignments::Vector{StaffingAssignment} = StaffingAssignment[]
    last_reputation::Float64 = 0.0           # sticky reputation: last computed rep when broker had clients
    has_had_clients::Bool = false             # whether broker has ever had any client
end

"""Immutable simulation parameters: population sizes, behavioral constants, and run config."""
struct ModelParams
    d::Int                       # type dimensionality
    s::Int                       # rank: projection and interaction (default 2)
    rho::Float64                 # general quality share Var(μ)/Var(f) (default 0.50)
    K_mu::Int                    # number of RBF centers (calibration parameter; default 10)
    N_W::Int                     # worker count
    N_F::Int                     # firm count
    eta::Float64                 # firm exit rate
    beta_W::Float64              # worker surplus share
    k_nn::Int                    # k for k-NN (structural constant, fixed at 10)
    k_S::Int                     # social network degree (structural constant, not swept)
    p_rewire::Float64            # rewiring probability (structural constant, not swept)
    omega::Float64               # satisfaction recency weight (structural constant, fixed at 0.3)
    alpha::Float64               # placement fee rate (fixed at 0.20; §7b)
    L::Int                       # fee amortization period (§6a); reused as staffing assignment length in M1 (§9)
    mu_b::Float64                # staffing value-capture rate
    c_emp_frac::Float64          # employment cost as fraction of r_base
    p_vac::Float64               # per-period vacancy probability (structural constant, fixed at 0.10)
    pool_target_frac::Float64    # broker pool target as fraction of N_W (0.20; P = ⌈frac · N_W⌉)
    n_candidates_frac::Float64   # candidates as fraction of N_W (0.01)
    network_measure_interval::Int # M
    T::Int                       # total periods
    T_burn::Int                  # burn-in periods discarded from analysis (default 20)
    seed::Int
end

"""Deterministic component of the matching function mu(w) + w'Ax: interaction matrix, projection, and RBF components."""
struct MatchingEnv
    A::Matrix{Float64}                       # d×d interaction matrix of rank s
    U::Matrix{Float64}                       # d×s worker skill basis of A
    P::Matrix{Float64}                       # s×d projection matrix (rows ⊥ colspan(U))
    mu_centers::Matrix{Float64}              # s × K_μ RBF centers (columns)
    mu_weights::Vector{Float64}              # K_μ RBF amplitudes (scaled so Var(μ)/Var(f) = ρ)
    mu_bandwidth::Float64                    # calibrated RBF bandwidth h
end

"""Output-scale constants derived from Monte Carlo calibration: reservation wage floor, mean output, and public benchmark."""
struct CalibrationConstants
    r_base::Float64               # calibrated reservation wage floor
    f_bar::Float64                # mean |μ(w) + w⊤Ax|
    q_pub::Float64                # public benchmark
end

"""k-NN prediction output: predicted quality, epistemic uncertainty, and aleatoric uncertainty."""
struct PredictionResult
    q_hat::Float64        # predicted match quality
    mean_dist::Float64    # average neighbor distance (epistemic uncertainty)
    neighbor_var::Float64 # neighbor outcome variance (aleatoric uncertainty)
end

"""Preallocated index, distance, and weight buffers for k-NN queries."""
mutable struct PredictionCache
    idxs::Vector{Int}
    dists::Vector{Float64}
    weights::Vector{Float64}
end
PredictionCache(k::Int) = PredictionCache(zeros(Int, k), zeros(Float64, k), zeros(Float64, k))

"""Per-period KDTrees and precomputed residuals: per-firm trees, broker Stage 1, and broker Stage 2."""
struct PeriodTrees
    firm_trees::Vector{Union{Nothing, KDTree}}
    broker_s1_tree::Union{Nothing, KDTree}
    broker_s2_trees::Dict{Int, KDTree}
    broker_s2_residuals::Dict{Int, Vector{Float64}}
end

"""Prediction quality over a window: R-squared, bias, and rank correlation."""
struct PredictionQuality
    r_squared::Float64
    bias::Float64
    rank_corr::Float64
end

"""Number of valid entries in a circular history buffer: min(total_writes, capacity)."""
effective_history_size(total::Int, cap::Int) = min(total, cap)
effective_history_size(firm::Firm) = effective_history_size(firm.history_count, size(firm.history_w, 2))
effective_history_size(broker::Broker) = effective_history_size(broker.history_count, size(broker.history_w, 2))

"""Per-period counters, output vectors, and prediction pairs. All fields reset each tick except cumulative revenue totals."""
Base.@kwdef mutable struct PeriodAccumulators
    matches::Int = 0
    new_staffing::Int = 0
    new_placements::Int = 0
    q_direct::Vector{Float64} = Float64[]
    q_placed::Vector{Float64} = Float64[]
    q_staffed::Vector{Float64} = Float64[]
    openings_internal::Int = 0
    openings_brokered::Int = 0
    vacancies_internal::Int = 0
    vacancies_brokered::Int = 0
    access_count::Int = 0
    assessment_count::Int = 0
    outsourcing_rate::Float64 = 0.0
    # Confidence byproducts (prediction quality, §8)
    firm_mean_dists::Vector{Float64} = Float64[]
    firm_neighbor_vars::Vector{Float64} = Float64[]
    broker_mean_dists::Vector{Float64} = Float64[]
    broker_neighbor_vars::Vector{Float64} = Float64[]
    # Prediction/outcome pairs for R-squared computation
    firm_predicted::Vector{Float64} = Float64[]
    firm_realized::Vector{Float64} = Float64[]
    broker_predicted::Vector{Float64} = Float64[]
    broker_realized::Vector{Float64} = Float64[]
    # Revenue accumulators
    placement_revenue::Float64 = 0.0         # Π_b from placement fees this period
    staffing_revenue::Float64 = 0.0          # Π_b from staffing profit this period
    # Cumulative revenue (not reset each period)
    cumulative_placement_revenue::Float64 = 0.0
    cumulative_staffing_revenue::Float64 = 0.0
end

"""Zero all per-period fields in `a`, preserving cumulative revenue totals."""
function reset_accumulators!(a::PeriodAccumulators)
    a.matches = 0
    a.new_staffing = 0
    a.new_placements = 0
    empty!(a.q_direct)
    empty!(a.q_placed)
    empty!(a.q_staffed)
    a.openings_internal = 0
    a.openings_brokered = 0
    a.vacancies_internal = 0
    a.vacancies_brokered = 0
    a.access_count = 0
    a.assessment_count = 0
    a.outsourcing_rate = 0.0
    empty!(a.firm_mean_dists)
    empty!(a.firm_neighbor_vars)
    empty!(a.broker_mean_dists)
    empty!(a.broker_neighbor_vars)
    empty!(a.firm_predicted)
    empty!(a.firm_realized)
    empty!(a.broker_predicted)
    empty!(a.broker_realized)
    a.placement_revenue = 0.0
    a.staffing_revenue = 0.0
    # cumulative fields are NOT reset
    return nothing
end

"""Broker's network position measures, recomputed every M periods on the combined graph."""
mutable struct CachedNetworkMeasures
    betweenness::Float64      # Freeman betweenness centrality (normalized)
    constraint::Float64       # Burt's network constraint (low = spanning structural holes)
    effective_size::Float64   # Burt's effective size (non-redundant contacts)
end

"""Complete simulation state: all agents, network, environment, and accumulators."""
Base.@kwdef mutable struct ModelState
    params::ModelParams
    rng::StableRNG
    period::Int = 0
    env::MatchingEnv
    cal::CalibrationConstants
    workers::Vector{Worker}
    firms::Vector{Firm}
    broker::Broker                # single broker (v9 simplification)
    G_S::SimpleGraph{Int}         # social network
    open_vacancies::Set{Int} = Set{Int}()
    next_firm_id::Int
    accum::PeriodAccumulators = PeriodAccumulators()
    cached_network::CachedNetworkMeasures
end
