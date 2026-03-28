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
    # W_centered is d × n
    # Normal equations: beta = (WW' + lambda*I)^{-1} W (q - q_mean)
    # where W is centered
    q_centered = q .- q_mean
    # For small d (typical: 4-12), direct solve is fine
    WWT = zeros(d, d)
    Wq = zeros(d)
    @inbounds for i in 1:n
        for k1 in 1:d
            wk1 = W[k1, i] - w_mean[k1]
            Wq[k1] += wk1 * q_centered[i]
            for k2 in 1:d
                WWT[k1, k2] += wk1 * (W[k2, i] - w_mean[k2])
            end
        end
    end
    for k in 1:d
        WWT[k, k] += lambda
    end
    beta = WWT \ Wq
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

"""Construct broker feature vector [w; x; w.*x; w.^2] for prediction."""
broker_features(w::AbstractVector, x::AbstractVector) = vcat(w, x, w .* x, w .^ 2)


"""
    build_period_models(state, lambda) -> PeriodModels

Fit ridge regression models for all firms (features = [w; w.^2]) and for
the broker (features = [w; x; w.*x; w.^2]). The w.^2 features capture
quadratic nonlinearity in general worker quality mu(w).
"""
function build_period_models(state::ModelState, lambda::Float64)::PeriodModels
    # Firm models: q ≈ beta'[w; w.^2] + c
    firm_models = [begin
        n = effective_history_size(firm)
        W = @view(firm.history_w[:, 1:n])
        fit_ridge(vcat(W, W .^ 2), @view(firm.history_q[1:n]), lambda)
    end for firm in state.firms]

    # Broker model: q ≈ beta'[w; x; w.*x; w.^2] + c
    broker = state.broker
    n_b = effective_history_size(broker)
    W = @view(broker.history_w[:, 1:n_b])
    X = @view(broker.history_x[:, 1:n_b])
    WXI = vcat(W, X, W .* X, W .^ 2)
    broker_model = fit_ridge(WXI, @view(broker.history_q[1:n_b]), lambda)

    return PeriodModels(firm_models, broker_model)
end

