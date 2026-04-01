"""
    learning.jl

Ridge regression prediction for firms and brokers, model fitting, and predict-and-record wrappers.
"""

"""
    RidgeModel

Fitted ridge regression: q_hat = beta'w + intercept.
`beta` is the d-dimensional coefficient vector, `intercept` the bias term.
"""
struct RidgeModel
    beta::Vector{Float64}
    intercept::Float64
end

"""
    fit_ridge(W, q, lambda) -> RidgeModel

Fit ridge regression q ≈ W'beta + intercept, where W is d × n (columns are observations)
and q is n-vector of outcomes. Returns RidgeModel with coefficients and intercept.
"""
function fit_ridge(W::AbstractMatrix{Float64}, q::AbstractVector{Float64},
                   lambda::Float64)::RidgeModel
    d, n = size(W)
    # Center
    w_mean = vec(sum(W, dims=2)) ./ n
    q_mean = sum(q) / n
    # Build centered feature matrix
    W_c = W .- w_mean
    q_c = q .- q_mean
    # Normal equations via BLAS: beta = (W_c W_c' + lambda I)^{-1} W_c q_c
    WWT = W_c * W_c'
    Wq = W_c * q_c
    for k in 1:d
        WWT[k, k] += lambda
    end
    # Cholesky solve (WWT + λI is symmetric positive definite)
    beta = cholesky!(Symmetric(WWT)) \ Wq
    intercept = q_mean - dot(beta, w_mean)
    return RidgeModel(beta, intercept)
end

"""
    predict_ridge(model, w) -> Float64

Predict outcome for worker type `w` using a fitted ridge model.
"""
function predict_ridge(model::RidgeModel, w::AbstractVector{Float64})::Float64
    return dot(model.beta, w) + model.intercept
end

"""Pre-fitted regression models for the current period: one per firm and one for the broker."""
struct PeriodModels
    firm_models::Vector{RidgeModel}
    broker_model::RidgeModel
end

"""Construct firm feature vector [w; w.^2] for prediction."""
firm_features(w::AbstractVector) = vcat(w, w .^ 2)

"""Construct broker feature vector [w; x; vec(w*x'); w.^2] for prediction.
Includes full outer product w⊗x (d² features) to capture cross-dimensional interactions."""
function broker_features(w::AbstractVector, x::AbstractVector)
    d = length(w)
    wx = Vector{Float64}(undef, d * d)
    idx = 0
    @inbounds for l in 1:d, k in 1:d
        idx += 1
        wx[idx] = w[k] * x[l]
    end
    return vcat(w, x, wx, w .^ 2)
end

"""Broker feature dimension: 2d + d² + d = d² + 3d."""
broker_feature_dim(d::Int) = d * d + 3 * d

"""Write firm features [w; w.^2] into `buf` and predict. Zero-allocation hot path."""
function predict_ridge!(model::RidgeModel, buf::Vector{Float64}, w::AbstractVector)
    d = length(w)
    @views buf[1:d] .= w
    @views @. buf[d+1:2d] = w ^ 2
    return dot(model.beta, buf) + model.intercept
end

"""Write broker features [w; x; vec(w*x'); w.^2] into `buf` and predict. Zero-allocation hot path."""
function predict_ridge!(model::RidgeModel, buf::Vector{Float64},
                        w::AbstractVector, x::AbstractVector)
    d = length(w)
    @views buf[1:d] .= w
    @views buf[d+1:2d] .= x
    # Full outer product w⊗x
    offset = 2d
    @inbounds for l in 1:d, k in 1:d
        offset += 1
        buf[offset] = w[k] * x[l]
    end
    # w²
    @views @. buf[2d + d*d + 1 : 2d + d*d + d] = w ^ 2
    return dot(model.beta, buf) + model.intercept
end


"""
    build_period_models(state, lambda) -> PeriodModels

Fit ridge regression models for all firms (features = [w; w²], 2d dims) and for
the broker (features = [w; x; w⊗x; w²], d²+3d dims). The full outer product
w⊗x captures cross-dimensional interactions from the interaction matrix A.
"""
function build_period_models(state::ModelState, lambda::Float64)::PeriodModels
    d = state.params.d

    # Firm models: q ≈ beta'[w; w²] + alpha
    firm_models = [begin
        n = effective_history_size(firm)
        W = @view(firm.history_w[:, 1:n])
        fit_ridge(vcat(W, W .^ 2), @view(firm.history_q[1:n]), lambda)
    end for firm in state.firms]

    # Broker model: q ≈ beta'[w; x; w⊗x; w²] + alpha
    broker = state.broker
    n_b = effective_history_size(broker)
    W = @view(broker.history_w[:, 1:n_b])
    X = @view(broker.history_x[:, 1:n_b])
    # Build feature matrix: [w; x; outer_product; w²]
    n_bf = broker_feature_dim(d)
    BF = Matrix{Float64}(undef, n_bf, n_b)
    @inbounds for i in 1:n_b
        offset = 0
        for k in 1:d; BF[offset + k, i] = W[k, i]; end
        offset += d
        for k in 1:d; BF[offset + k, i] = X[k, i]; end
        offset += d
        for l in 1:d, k in 1:d
            offset += 1
            BF[offset, i] = W[k, i] * X[l, i]
        end
        for k in 1:d; BF[d*d + 2d + k, i] = W[k, i]^2; end
    end
    broker_model = fit_ridge(BF, @view(broker.history_q[1:n_b]), lambda)

    return PeriodModels(firm_models, broker_model)
end

