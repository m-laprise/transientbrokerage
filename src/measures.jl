"""
    measures.jl

Prediction quality measures: R-squared, bias, and rank correlation.
"""

"""
    compute_prediction_quality(predicted, realized) -> PredictionQuality

R-squared, bias, and Spearman rank correlation over paired prediction/outcome vectors.
Returns NaN for all fields when fewer than 5 observations.
"""
function compute_prediction_quality(predicted::Vector{Float64},
                                    realized::Vector{Float64})::PredictionQuality
    n = length(predicted)
    n < 5 && return PredictionQuality(NaN, NaN, NaN)
    mse = 0.0
    bias = 0.0
    @inbounds for i in 1:n
        e = predicted[i] - realized[i]
        mse += e * e
        bias += e
    end
    mse /= n
    bias /= n
    var_q = var(realized)
    r2 = var_q > 0 ? 1.0 - mse / var_q : NaN
    rank_corr = corspearman(predicted, realized)
    return PredictionQuality(r2, bias, rank_corr)
end
