module TransientBrokerage

using Graphs: SimpleGraph, watts_strogatz, neighbors, degree, vertices,
              edges, src, dst, add_edge!, has_edge, ne, nv, star_graph
using StableRNGs: StableRNG
using LinearAlgebra: dot, norm, mul!, Symmetric, cholesky!, qr
using Random: AbstractRNG, randn!
using StatsBase: median, sample, Weights, corspearman
using Statistics: var, mean
using MultivariateStats: fit, predict, PCA
using DataFrames: DataFrame

include("types.jl")
include("parameters.jl")
include("matching_function.jl")
include("network.jl")
include("initialization.jl")
include("learning.jl")
include("measures.jl")
include("search.jl")
include("matching.jl")
include("staffing.jl")
include("entry_exit.jl")
include("step.jl")
include("invariants.jl")
include("simulation.jl")
include("diagnostics.jl")

export WorkerStatus, available, employed, staffed
export Worker, Firm, StaffingAssignment, Broker, ProposedMatch, effective_history_size
export ModelParams, MatchingEnv, CalibrationConstants
export RidgeModel, PeriodModels, PredictionQuality
export PeriodAccumulators, reset_accumulators!
export CachedNetworkMeasures, ModelState
export default_params, validate_params
export generate_matching_function, cosine_sim, eval_mu, eval_interaction, eval_interaction!
export match_output, match_output_noiseless, match_output_noiseless!, calibrate_output_scale
export build_social_network, compute_referral_pool!, compute_all_referral_pools!
export FirmGeometry, generate_firm_geometry, sample_firm_type, generate_firm_types
export compute_reservation_wage, create_firm, create_broker
export assign_initial_employment!, initialize_model
export fit_ridge, predict_ridge, predict_ridge!, build_period_models, firm_features, broker_features, broker_feature_dim
export compute_prediction_quality
export build_combined_graph, compute_crossmode_betweenness, compute_burt_constraint
export compute_effective_size, update_cached_network_measures!
export internal_search, broker_allocate!
export compute_wage, resolve_conflicts, finalize_match!
export record_history!, record_broker_history!
export update_satisfaction!, penalize_no_proposal!, record_match!
export outsourcing_decision, broker_reputation, update_broker_reputation!
export broker_prefers_staffing, firm_accepts_staffing
export create_staffing_assignment!, process_staffing_economics!
export release_staffed_worker!, terminate_firm_assignments!
export exit_firm!, enter_firm!, process_entry_exit!
export step_period!, verify_invariants
export collect_period_metrics, run_simulation, diagnostic_summary

end # module
