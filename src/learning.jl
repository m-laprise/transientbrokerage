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
    w_mean = Vector{Float64}(undef, d)
    fill!(w_mean, 0.0)
    @inbounds for j in 1:n, k in 1:d
        w_mean[k] += W[k, j]
    end
    w_mean ./= n
    q_mean = sum(q) / n
    # Build centered feature matrix
    W_c = Matrix{Float64}(undef, d, n)
    @inbounds for j in 1:n, k in 1:d
        W_c[k, j] = W[k, j] - w_mean[k]
    end
    q_c = Vector{Float64}(undef, n)
    @inbounds for j in 1:n
        q_c[j] = q[j] - q_mean
    end
    # Normal equations via BLAS: beta = (W_c W_c' + lambda I)^{-1} W_c q_c
    WWT = W_c * W_c'
    Wq = W_c * q_c
    @inbounds for k in 1:d
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

"""Firm prediction: write features [w; w²] into `buf` (length 2d) and return ŷ. Zero-allocation."""
function predict_ridge!(model::RidgeModel, buf::Vector{Float64}, w::AbstractVector)
    d = length(w)
    @views buf[1:d] .= w
    @views @. buf[d+1:2d] = w ^ 2
    return dot(model.beta, buf) + model.intercept
end

"""Broker prediction: write features [w; x; vec(w⊗x); w²] into `buf` (length d²+3d) and return ŷ. Zero-allocation."""
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
    firms = state.firms

    # Pre-allocate shared firm feature matrix [w; w²], reused across firms
    max_firm_n = 0
    for f in firms
        n = effective_history_size(f)
        n > max_firm_n && (max_firm_n = n)
    end
    FF = Matrix{Float64}(undef, 2d, max_firm_n)

    firm_models = Vector{RidgeModel}(undef, length(firms))
    for (idx, firm) in enumerate(firms)
        n = effective_history_size(firm)
        W = @view(firm.history_w[:, 1:n])
        @views FF[1:d, 1:n] .= W
        @views @. FF[d+1:2d, 1:n] = W ^ 2
        firm_models[idx] = fit_ridge(@view(FF[:, 1:n]), @view(firm.history_q[1:n]), lambda)
    end

    # Broker model: q ≈ beta'[w; x; w⊗x; w²] + alpha
    broker = state.broker
    n_b = effective_history_size(broker)
    W_b = @view(broker.history_w[:, 1:n_b])
    X_b = @view(broker.history_x[:, 1:n_b])
    # Build feature matrix: [w; x; outer_product; w²]
    n_bf = broker_feature_dim(d)
    BF = Matrix{Float64}(undef, n_bf, n_b)
    d2 = d * d
    @inbounds for i in 1:n_b
        for k in 1:d; BF[k, i] = W_b[k, i]; end
        for k in 1:d; BF[d + k, i] = X_b[k, i]; end
        base = 2d
        for l in 1:d
            off = base + (l - 1) * d
            xi_l = X_b[l, i]
            for k in 1:d
                BF[off + k, i] = W_b[k, i] * xi_l
            end
        end
        for k in 1:d; BF[d2 + 2d + k, i] = W_b[k, i] * W_b[k, i]; end
    end
    broker_model = fit_ridge(BF, @view(broker.history_q[1:n_b]), lambda)

    return PeriodModels(firm_models, broker_model)
end

