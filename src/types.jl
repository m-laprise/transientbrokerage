"""
    types.jl

Agent types, model state, and supporting structs for the Transient Brokerage ABM (v0.2).
Unimodal matching market: N agents + 1 broker on a single network G.
"""

# ─────────────────────────────────────────────────────────────────────────────
# Neural network
# ─────────────────────────────────────────────────────────────────────────────

"""One-hidden-layer ReLU network: y = w2' * relu(W1 * z + b1) + b2."""
mutable struct NeuralNet
    W1::Matrix{Float64}   # h x d_in
    b1::Vector{Float64}   # h
    w2::Vector{Float64}   # h
    b2::Float64           # scalar
end

"""Pre-allocated gradient and activation buffers matching a NeuralNet's shape.
Owning these per-NN (rather than per-thread) keeps training thread-safe:
each agent's NN and its buffers can be trained concurrently without locks."""
mutable struct NNGradBuffers
    dW1::Matrix{Float64}  # h x d_in  (gradient of W1)
    db1::Vector{Float64}  # h         (gradient of b1)
    dw2::Vector{Float64}  # h         (gradient of w2)
    db2::Base.RefValue{Float64}       # scalar gradient of b2

    # Forward/backward activation scratch. Grow on demand to at most
    # TRAIN_WINDOW columns in the hot path.
    Z1::Matrix{Float64}   # h x n  pre-activations
    A::Matrix{Float64}    # h x n  post-ReLU activations
    dZ1::Matrix{Float64}  # h x n  gradient wrt pre-activations
    Y::Vector{Float64}    # n      predictions, reused as residuals
end

"""Create zero-initialized gradient buffers matching `nn`."""
function NNGradBuffers(nn::NeuralNet)
    h, d_in = size(nn.W1)
    return NNGradBuffers(
        zeros(h, d_in),
        zeros(h),
        zeros(h),
        Ref(0.0),
        Matrix{Float64}(undef, h, 0),
        Matrix{Float64}(undef, h, 0),
        Matrix{Float64}(undef, h, 0),
        Float64[],
    )
end

"""Ensure the activation scratch buffers are sized for at least n columns.
Grows with doubling to amortize resizes across training calls."""
function ensure_nn_buffers!(grad::NNGradBuffers, h::Int, n::Int)
    cur = size(grad.Z1, 2)
    if cur < n
        new_cap = max(n, 2 * cur, 16)
        grad.Z1 = Matrix{Float64}(undef, h, new_cap)
        grad.A = Matrix{Float64}(undef, h, new_cap)
        grad.dZ1 = Matrix{Float64}(undef, h, new_cap)
        resize!(grad.Y, new_cap)
    end
    return nothing
end

# ─────────────────────────────────────────────────────────────────────────────
# Current-period match tracking
# ─────────────────────────────────────────────────────────────────────────────

"""A single current-period match in an agent's match list. The same partner may
appear multiple times (concurrent matches with the same counterparty are allowed)."""
struct ActiveMatch
    partner_id::Int
    is_principal::Bool   # false = standard brokered or self-search; true = principal mode (Model 1)
    channel::Symbol      # :self or :broker
end

# ─────────────────────────────────────────────────────────────────────────────
# Agent
# ─────────────────────────────────────────────────────────────────────────────

"""Market participant with a type, prediction model, match history, and satisfaction scores."""
Base.@kwdef mutable struct Agent
    id::Int
    type::Vector{Float64}                    # x_i on the unit sphere, length d

    # Current-period matches (list, allows duplicates; length <= K)
    active_matches::Vector{ActiveMatch} = ActiveMatch[]

    # Experience history: d x capacity matrix (column-major, doubling growth)
    # Column j holds the partner type from the j-th match
    history_X::Matrix{Float64}               # d x capacity
    history_q::Vector{Float64}               # realized outputs, matching columns of history_X
    history_count::Int = 0                   # total observations recorded

    # Neural network and prediction buffer
    nn::NeuralNet
    nn_grad::NNGradBuffers                   # pre-allocated gradient buffers
    predict_buf::Vector{Float64}             # length h_a, for zero-alloc forward pass
    n_new_obs::Int = 0                       # observations since last training (for adaptive schedule)

    # Per-partner average tracking (direct-indexed by partner agent ID)
    partner_sum::Vector{Float64}             # length N; sum of realized q for matches with partner j
    partner_count::Vector{Int}               # length N; count of matches with partner j

    # Satisfaction indices (EWMA)
    satisfaction_self::Float64 = 0.0
    satisfaction_broker::Float64 = 0.0
    tried_broker::Bool = false

    # Roster membership: period of last outsourcing decision (0 = never outsourced).
    # Agent stays on roster for ROSTER_LAG periods after last outsourcing.
    last_outsource_period::Int = 0

    # Tenure
    periods_alive::Int = 0

    # Cumulative match counters for broker-dependency D_j (§12i).
    # n_matches_any: every accepted match the agent has participated in, any role, any channel.
    # n_principal_acquired: subset where the agent was the counterparty acquired in principal mode.
    # Reset to zero on entry; not decremented on match expiration.
    n_matches_any::Int = 0
    n_principal_acquired::Int = 0
end

"""Number of valid history entries for an agent."""
effective_history_size(agent::Agent) = agent.history_count

"""Available capacity: K minus active matches."""
available_capacity(agent::Agent, K::Int) = K - length(agent.active_matches)

"""Is the agent on the broker's roster? True if outsourced within ROSTER_LAG periods."""
is_on_roster(agent::Agent, current_period::Int) = agent.last_outsource_period > 0 &&
    (current_period - agent.last_outsource_period) <= ROSTER_LAG

"""Mean realized output with partner j, or NaN if no prior match."""
function partner_mean(agent::Agent, j::Int)
    c = agent.partner_count[j]
    return c > 0 ? agent.partner_sum[j] / c : NaN
end

"""Record a new observation to agent's history, growing the buffer if needed."""
function record_agent_history!(agent::Agent, partner_type::AbstractVector{Float64}, q::Float64)
    agent.history_count += 1
    agent.n_new_obs += 1
    n = agent.history_count
    cap = size(agent.history_X, 2)

    # Grow buffer if needed (doubling strategy)
    if n > cap
        new_cap = max(2 * cap, 16)
        d = size(agent.history_X, 1)
        new_X = Matrix{Float64}(undef, d, new_cap)
        new_X[:, 1:cap] .= agent.history_X
        agent.history_X = new_X
        resize!(agent.history_q, new_cap)
    end

    agent.history_X[:, n] .= partner_type
    agent.history_q[n] = q
    return nothing
end

"""Update per-partner sum and count after a match with partner j."""
function update_partner_mean!(agent::Agent, partner_id::Int, q::Float64)
    agent.partner_sum[partner_id] += q
    agent.partner_count[partner_id] += 1
    return nothing
end

# ─────────────────────────────────────────────────────────────────────────────
# Proposed match (for conflict resolution)
# ─────────────────────────────────────────────────────────────────────────────

"""A proposed match before acceptance/rejection in the sequential formation step.

`ask_j` caches the counterparty's acquisition reservation q̄_j at the time of
mode selection (§12c). It is NaN for non-principal proposals and for principal proposals
where no reservation was computed (e.g., enable_principal=false). Caching at
mode-selection time keeps capture-surplus recording consistent with the broker's
ex-ante decision, even if the counterparty's history grows within the same period
through unrelated matches."""
struct ProposedMatch
    demander_id::Int
    counterparty_id::Int
    channel::Symbol         # :self or :broker
    evaluation::Float64     # q_hat (stranger) or q_bar (known neighbor) used for demander selection
    is_principal::Bool      # Model 1: broker takes one side
    ask_j::Float64          # acquisition reservation cached at mode selection; NaN if unused
end

# ─────────────────────────────────────────────────────────────────────────────
# Broker
# ─────────────────────────────────────────────────────────────────────────────

"""Single intermediary with a roster, cross-agent history, and prediction model."""
Base.@kwdef mutable struct Broker
    node_id::Int                              # permanent node in G (= N + 1)
    roster::Set{Int} = Set{Int}()             # agent IDs on the broker's roster

    # Experience history: d x capacity matrices (column-major, doubling growth)
    history_Xi::Matrix{Float64}               # demander types
    history_Xj::Matrix{Float64}               # counterparty types
    history_q::Vector{Float64}                # realized outputs
    history_count::Int = 0

    # Neural network
    nn::NeuralNet
    nn_grad::NNGradBuffers
    predict_buf::Vector{Float64}              # length h_b
    n_new_obs::Int = 0

    # Pre-allocated training matrix for symmetry augmentation (2d x 2*capacity)
    train_X::Matrix{Float64}
    train_q::Vector{Float64}

    # Reputation
    last_reputation::Float64 = 0.0
    has_had_clients::Bool = false

    # Capture confidence and counterparty support:
    # - capture_confidence_mae: EWMA of recent realized broker-match absolute errors
    # - capture_confidence_ready: whether live broker-realized matches have initialized κ
    # - counterparty_support[j]: number of distinct demanders previously matched with j
    # - support_seen[i, j]: whether demander i has ever been broker-matched with j
    capture_confidence_mae::Float64 = 0.0
    capture_confidence_ready::Bool = false
    counterparty_support::Vector{Int} = Int[]
    support_seen::Matrix{Bool} = zeros(Bool, 0, 0)
end

"""Number of valid history entries for the broker."""
effective_history_size(broker::Broker) = broker.history_count

"""Record a brokered observation to the broker's history, growing buffers if needed."""
function record_broker_history!(broker::Broker, xi::AbstractVector{Float64},
                                xj::AbstractVector{Float64}, q::Float64)
    broker.history_count += 1
    broker.n_new_obs += 1
    n = broker.history_count
    cap = size(broker.history_Xi, 2)

    # Grow buffers if needed
    if n > cap
        d = size(broker.history_Xi, 1)
        new_cap = max(2 * cap, 32)
        new_Xi = Matrix{Float64}(undef, d, new_cap)
        new_Xi[:, 1:cap] .= broker.history_Xi
        broker.history_Xi = new_Xi
        new_Xj = Matrix{Float64}(undef, d, new_cap)
        new_Xj[:, 1:cap] .= broker.history_Xj
        broker.history_Xj = new_Xj
        resize!(broker.history_q, new_cap)

        # Also grow symmetry-augmented training buffers
        new_train_cap = 2 * new_cap
        d2 = size(broker.train_X, 1)  # 2d
        new_train_X = Matrix{Float64}(undef, d2, new_train_cap)
        broker.train_X = new_train_X
        resize!(broker.train_q, new_train_cap)
    end

    broker.history_Xi[:, n] .= xi
    broker.history_Xj[:, n] .= xj
    broker.history_q[n] = q
    return nothing
end

# ─────────────────────────────────────────────────────────────────────────────
# Matching environment and calibration
# ─────────────────────────────────────────────────────────────────────────────

"""Matching environment: ideal type c, interaction matrix A, regime matrix B, and noise scale."""
struct MatchingEnv
    d::Int
    rho::Float64
    c::Vector{Float64}       # ideal type vector
    A::Matrix{Float64}       # SPD interaction matrix (M_A'M_A)
    B::Matrix{Float64}       # SPD regime matrix (M_B'M_B)
    delta::Float64            # gain strength
    sigma_eps::Float64        # match output noise SD
end

"""Output-scale constants derived from Monte Carlo calibration."""
struct CalibrationConstants
    q_cal::Float64     # calibration reference E[q] (scales r, phi, c_s; not used for initialization)
    r::Float64         # outside option (0.60 * q_cal)
    phi::Float64       # successful standard-placement fee
    c_s::Float64       # self-search cost per demanded slot
end

"""Prediction quality metrics: R-squared, bias, and rank correlation."""
struct PredictionQuality
    r_squared::Float64
    bias::Float64
    rank_corr::Float64
end

# ─────────────────────────────────────────────────────────────────────────────
# Type curve geometry
# ─────────────────────────────────────────────────────────────────────────────

"""Sinusoidal curve on the unit sphere with s active dimensions out of d.
Agent types are drawn at random positions on this curve, then perturbed."""
struct CurveGeometry
    d::Int
    s::Int                        # active dimensions (1..s have nonzero curve amplitude)
    freqs::Vector{Int}            # per-dimension integer frequencies (length s), from U{1,...,5}
    phases::Vector{Float64}       # per-dimension phases (length s), from U[0, 2π)
end

# ─────────────────────────────────────────────────────────────────────────────
# Period accumulators
# ─────────────────────────────────────────────────────────────────────────────

"""Per-period counters and output vectors. All fields reset each tick."""
Base.@kwdef mutable struct PeriodAccumulators
    # Match counts by channel
    n_self_matches::Int = 0
    n_broker_standard::Int = 0
    n_broker_principal::Int = 0

    # Realized output by channel
    q_self::Vector{Float64} = Float64[]
    q_broker_standard::Vector{Float64} = Float64[]
    q_broker_principal::Vector{Float64} = Float64[]

    # Parallel series for principal-mode matches (aligned with q_broker_principal):
    # - q_bar_j_principal: acquisition reservation q̄_j used at mode selection (§12c)
    # - q_hat_b_principal: broker's ex-ante predicted match output q̂_b
    # Together with q_broker_principal these feed the capture outcome and decision
    # quality metrics (§12i).
    q_bar_j_principal::Vector{Float64} = Float64[]
    q_hat_b_principal::Vector{Float64} = Float64[]

    # Distinct counterparties acquired in principal mode this period (for supply scarcity)
    principal_acquired_ids::Set{Int} = Set{Int}()

    # Access vs assessment decomposition
    access_count::Int = 0       # counterparty was NOT a neighbor of demander
    assessment_count::Int = 0   # counterparty WAS a neighbor

    # Outsourcing rate and demand
    n_demanders::Int = 0
    n_outsourced::Int = 0           # demanders who chose the broker channel
    outsourced_slots::Int = 0       # demand slots routed through the broker channel
    total_demand::Int = 0           # total demand slots across all demanders

    # Prediction/outcome pairs from actual matches (subject to selection bias)
    agent_predicted::Vector{Float64} = Float64[]
    agent_realized::Vector{Float64} = Float64[]
    broker_predicted::Vector{Float64} = Float64[]
    broker_realized::Vector{Float64} = Float64[]
    broker_error_abs_sum::Float64 = 0.0
    broker_error_count::Int = 0
    broker_confidence_mae::Float64 = NaN

    # Holdout: per-agent averaged over sampled agents (both agent and broker
    # evaluated on the same per-agent partner sets for comparability)
    agent_holdout_r2::Float64 = NaN
    agent_holdout_bias::Float64 = NaN
    agent_holdout_rank::Float64 = NaN
    agent_holdout_rmse::Float64 = NaN
    broker_holdout_r2::Float64 = NaN
    broker_holdout_bias::Float64 = NaN
    broker_holdout_rank::Float64 = NaN
    broker_holdout_rmse::Float64 = NaN

    # Roster
    roster_size::Int = 0
end

"""Zero all per-period fields, preserving cumulative revenue totals."""
function reset_accumulators!(a::PeriodAccumulators)
    a.n_self_matches = 0
    a.n_broker_standard = 0
    a.n_broker_principal = 0
    empty!(a.q_self)
    empty!(a.q_broker_standard)
    empty!(a.q_broker_principal)
    empty!(a.q_bar_j_principal)
    empty!(a.q_hat_b_principal)
    empty!(a.principal_acquired_ids)
    a.access_count = 0
    a.assessment_count = 0
    a.n_demanders = 0
    a.n_outsourced = 0
    a.outsourced_slots = 0
    a.total_demand = 0
    empty!(a.agent_predicted)
    empty!(a.agent_realized)
    empty!(a.broker_predicted)
    empty!(a.broker_realized)
    a.broker_error_abs_sum = 0.0
    a.broker_error_count = 0
    a.broker_confidence_mae = NaN
    a.agent_holdout_r2 = NaN
    a.agent_holdout_bias = NaN
    a.agent_holdout_rank = NaN
    a.agent_holdout_rmse = NaN
    a.broker_holdout_r2 = NaN
    a.broker_holdout_bias = NaN
    a.broker_holdout_rank = NaN
    a.broker_holdout_rmse = NaN
    a.roster_size = 0
    return nothing
end

# ─────────────────────────────────────────────────────────────────────────────
# Network measures cache
# ─────────────────────────────────────────────────────────────────────────────

"""Broker's network position measures, recomputed periodically."""
mutable struct CachedNetworkMeasures
    betweenness::Float64      # standard Freeman betweenness (broker node in G)
    constraint::Float64       # Burt's constraint (broker's ego network)
    effective_size::Float64   # Burt's effective size (non-redundant contacts)
end

CachedNetworkMeasures() = CachedNetworkMeasures(0.0, 1.0, 0.0)

# ─────────────────────────────────────────────────────────────────────────────
# Model parameters
# ─────────────────────────────────────────────────────────────────────────────

"""Immutable simulation parameters for the unimodal matching model."""
struct ModelParams
    # Population and types
    N::Int                       # agent count (default 1000)
    d::Int                       # type dimensionality (fixed at 8)
    s::Int                       # active dimensions of type curve (default 8; swept {2,4,6,8})

    # Matching function
    rho::Float64                 # quality-interaction mixing weight (default 0.50)
    delta::Float64               # regime gain strength (default 0.5)
    sigma_x::Float64             # type noise scale (default 0.5)
    sigma_eps::Float64           # match output noise SD (default 0.10)

    # Match accounting
    K::Int                       # match capacity (default 5)
    p_demand::Float64            # per-slot demand probability (default 0.50)

    # Network
    k::Int                       # Watts-Strogatz ring lattice degree (default 6)
    p_rewire::Float64            # rewiring probability (default 0.1)

    # Economics
    omega::Float64               # satisfaction recency weight (default 0.3)
    cost_wedge::Float64          # broker-minus-self cost wedge on the surplus scale (default 0.10)

    # Neural network
    eta_lr::Float64              # learning rate (default 0.03)
    E_init::Int                  # initial training steps (default 200)
    h_a::Int                     # agent hidden layer width (default 16)
    h_b::Int                     # broker hidden layer width (default 32)

    # Search
    n_strangers::Int             # max strangers in self-search (default 5)
    eta::Float64                 # agent entry/exit rate (default 0.02)

    # Model 1 toggle
    enable_principal::Bool       # resource capture mode (default false)

    # Simulation
    network_measure_interval::Int # M (default 10)
    T::Int                       # total periods (default 200)
    T_burn::Int                  # burn-in periods (default 30)
    seed::Int                    # RNG seed
end

# ─────────────────────────────────────────────────────────────────────────────
# Model state
# ─────────────────────────────────────────────────────────────────────────────

"""
Pre-allocated per-step scratch buffers reused across agents and calls.
Lives on ModelState; reset between uses via `empty!` on the vector fields.
"""
Base.@kwdef mutable struct SimWorkspace
    # self_search scratch
    neighbor_ids::Vector{Int} = Int[]
    neighbor_evals::Vector{Float64} = Float64[]
    neighbor_caps::Vector{Int} = Int[]
    stranger_ids::Vector{Int} = Int[]
    stranger_evals::Vector{Float64} = Float64[]
    stranger_caps::Vector{Int} = Int[]
    eligible::Vector{Int} = Int[]
    stranger_sample::Vector{Int} = Int[]
    # Neighbor bitset: nbr_mask[j] = true iff j is a neighbor of the current agent.
    # Length N+1 (extra slot for the broker node). Reset after each self_search call.
    nbr_mask::Vector{Bool} = Bool[]
    # Tracks which indices we set in nbr_mask this call, so we can clear only those.
    nbr_marked::Vector{Int} = Int[]

    # broker_allocate scratch
    demand_slots::Vector{Int} = Int[]
    roster_members::Vector{Int} = Int[]
    roster_capacity::Vector{Int} = Int[]
    # Quality matrix Q[demander_idx, roster_idx] (unique demanders x roster)
    Q::Matrix{Float64} = Matrix{Float64}(undef, 0, 0)
    z_buf::Vector{Float64} = Float64[]
    # Batched prediction scratch
    Z_batch::Matrix{Float64} = Matrix{Float64}(undef, 0, 0)  # 2d x n_pairs input
    H_batch::Matrix{Float64} = Matrix{Float64}(undef, 0, 0)  # h x n_pairs hidden
    Y_batch::Vector{Float64} = Float64[]                      # n_pairs output
    # Deduplication: demander_idx[agent_id] = position in unique_demanders (0 = unseen).
    # Length N, sparse-cleared after each call (like nbr_mask pattern).
    unique_demanders::Vector{Int} = Int[]
    demander_idx::Vector{Int} = Int[]
    demander_touched::Vector{Int} = Int[]  # which entries of demander_idx we set
    demander_remaining::Vector{Int} = Int[]  # slots remaining per unique demander
    # Sorted greedy: pre-allocated (negated_val, flat_index) pairs, sorted in-place.
    sort_pairs::Vector{Tuple{Float64, Int}} = Tuple{Float64, Int}[]

    # step_period! per-period scratch (avoids Dict/Set allocation each period)
    demand_agent_ids::Vector{Int} = Int[]     # agents with demand
    demand_channels::Vector{Symbol} = Symbol[]  # channel per demander
    demand_counts::Vector{Int} = Int[]        # d_i per demander
    client_demands_ws::Vector{Tuple{Int, Int}} = Tuple{Int, Int}[]
    broker_clients_ws::Vector{Int} = Int[]
    was_connected_i::Vector{Int} = Int[]  # pre-formation edge snapshot
    was_connected_j::Vector{Int} = Int[]
    remaining_cap::Vector{Int} = Int[]    # capacity tracker for match formation

    # Holdout evaluation scratch (reused each period in step.jl)
    Ax_buf::Vector{Float64} = Float64[]
    Bx_buf::Vector{Float64} = Float64[]
    holdout_z_buf::Vector{Float64} = Float64[]
end

"""Complete simulation state: all agents, broker, network, environment, and accumulators."""
Base.@kwdef mutable struct ModelState
    params::ModelParams
    rng::StableRNG
    period::Int = 0
    env::MatchingEnv
    cal::CalibrationConstants
    curve_geo::CurveGeometry
    agents::Vector{Agent}
    broker::Broker
    G::SimpleGraph{Int}                       # N+1 nodes: agents 1:N, broker at N+1
    accum::PeriodAccumulators = PeriodAccumulators()
    cached_network::CachedNetworkMeasures = CachedNetworkMeasures()
    workspace::SimWorkspace = SimWorkspace()
end
