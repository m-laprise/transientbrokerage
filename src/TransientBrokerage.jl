module TransientBrokerage

using Graphs: SimpleGraph, watts_strogatz, neighbors, degree, vertices
using StableRNGs: StableRNG
using LinearAlgebra: dot, norm, Diagonal, qr, mul!
using Random: AbstractRNG, randn!
using StatsBase: median, sample, Weights, corspearman
using Statistics: var, mean
using MultivariateStats: fit, predict, PCA
using NearestNeighbors: KDTree, knn!

include("types.jl")
include("parameters.jl")
include("matching_function.jl")
include("network.jl")
include("initialization.jl")
include("learning.jl")
include("measures.jl")
include("search.jl")
include("matching.jl")

export WorkerStatus, available, employed, staffed
export Worker, Firm, StaffingAssignment, Broker, ProposedMatch, effective_history_size
export ModelParams, MatchingEnv, CalibrationConstants
export PredictionResult, PredictionCache, PeriodTrees, PredictionQuality
export PeriodAccumulators, reset_accumulators!
export CachedNetworkMeasures, ModelState
export default_params, validate_params
export generate_matching_function, eval_mu!
export match_output!, match_output_noiseless!, calibrate_output_scale
export build_social_network, compute_referral_pool!, compute_all_referral_pools!
export compute_reservation_wage, create_firm, create_broker
export assign_initial_employment!, initialize_model
export predict_firm, predict_broker, build_period_trees
export predict_and_record_firm!, predict_and_record_broker!
export compute_prediction_quality
export internal_search, broker_allocate!
export compute_wage, resolve_conflicts, finalize_match!
export record_history!, record_broker_history!
export update_satisfaction!, penalize_no_proposal!, record_match!

end # module
