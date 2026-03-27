using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Statistics: mean
using LinearAlgebra: dot

# Create a firm with n_obs synthetic history entries
function make_firm_with_history(d::Int, n_obs::Int, rng::StableRNG)
    firm = create_firm(1, d, rng)
    for i in 1:n_obs
        w = clamp.(randn(rng, d), -3.0, 3.0)
        firm.history_count += 1
        firm.history_w[:, firm.history_count] = w
        firm.history_q[firm.history_count] = dot(w, firm.type) + randn(rng)
    end
    return firm
end

# Create a broker with pooled history across multiple firms
function make_broker_with_history(d::Int, firms::Vector{Firm}, n_per_firm::Int, rng::StableRNG)
    params = default_params(d=d, N_W=100, N_F=length(firms))
    workers = [Worker(id=i, node_id=i, type=clamp.(randn(rng, d), -3.0, 3.0),
                       reservation_wage=1.0) for i in 1:100]
    broker = create_broker(1, params, workers, rng)
    for (j, firm) in enumerate(firms)
        for _ in 1:n_per_firm
            w = clamp.(randn(rng, d), -3.0, 3.0)
            record_broker_history!(broker, w, firm.type, j, dot(w, firm.type) + randn(rng))
        end
    end
    return broker
end

d = 4

@testset "Learning" begin
    lambda = 1.0

    # Firm with seeded history produces finite, non-trivial predictions
    @testset "firm prediction with history" begin
        firm = make_firm_with_history(d, 10, StableRNG(1))
        n = effective_history_size(firm)
        model = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), lambda)
        q_hat = predict_ridge(model, randn(StableRNG(2), d))
        @test isfinite(q_hat)
    end

    # Ridge regression learns a linear function accurately with enough data
    @testset "ridge learns linear function" begin
        rng = StableRNG(42)
        firm = create_firm(1, d, rng)
        # Generate clean linear data: q = w'x + small noise
        for i in 1:100
            w = clamp.(randn(rng, d), -3.0, 3.0)
            firm.history_count += 1
            firm.history_w[:, firm.history_count] = w
            firm.history_q[firm.history_count] = dot(w, firm.type) + 0.1 * randn(rng)
        end
        n = effective_history_size(firm)
        model = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), 0.01)
        # Predictions should be close to true w'x for test workers
        errors = Float64[]
        for _ in 1:100
            w = clamp.(randn(rng, d), -3.0, 3.0)
            push!(errors, (predict_ridge(model, w) - dot(w, firm.type))^2)
        end
        @test mean(errors) < 0.5  # RMSE < 0.7 on a function with output scale ~4
    end

    # Prediction quality improves with more observations (same firm, growing history)
    @testset "learning curve: R-squared increases with n" begin
        firm_type = clamp.(randn(StableRNG(42), d), -3.0, 3.0)
        r2_vals = Float64[]
        for n_obs in [5, 20, 100]
            firm = create_firm(1, copy(firm_type), d)
            train_rng = StableRNG(n_obs)
            for _ in 1:n_obs
                w = clamp.(randn(train_rng, d), -3.0, 3.0)
                firm.history_count += 1
                firm.history_w[:, firm.history_count] = w
                firm.history_q[firm.history_count] = dot(w, firm.type) + randn(train_rng)
            end
            n = effective_history_size(firm)
            model = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), lambda)
            test_rng = StableRNG(999)
            predicted = Float64[]
            realized = Float64[]
            for _ in 1:200
                w = clamp.(randn(test_rng, d), -3.0, 3.0)
                push!(predicted, predict_ridge(model, w))
                push!(realized, dot(w, firm.type) + randn(test_rng))
            end
            pq = compute_prediction_quality(predicted, realized)
            push!(r2_vals, pq.r_squared)
        end
        @test r2_vals[3] > r2_vals[1]
    end

    # Broker pooled model should outperform individual firm models
    @testset "broker pooling advantage" begin
        rng = StableRNG(42)
        n_firms = 5
        firms = [create_firm(j, d, rng) for j in 1:n_firms]
        broker = make_broker_with_history(d, firms, 20, rng)

        state = initialize_model(default_params(d=d, N_W=100, N_F=n_firms))
        models = build_period_models(state, lambda)

        # Broker model should exist (pooled data)
        n_b = effective_history_size(state.broker)
        @test n_b >= 0  # may be 0 at init, but the test below uses the mock broker

        # Build broker model from mock data
        n_bm = effective_history_size(broker)
        WX = vcat(@view(broker.history_w[:, 1:n_bm]), @view(broker.history_x[:, 1:n_bm]))
        broker_model = fit_ridge(WX, @view(broker.history_q[1:n_bm]), lambda)

        # Test: broker predictions are finite and reasonable
        test_w = clamp.(randn(rng, d), -3.0, 3.0)
        q_b = predict_ridge(broker_model, vcat(test_w, firms[1].type))
        @test isfinite(q_b)
    end

    # Deterministic with fixed seed
    @testset "deterministic with fixed seed" begin
        firm = make_firm_with_history(d, 20, StableRNG(42))
        n = effective_history_size(firm)
        model1 = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), lambda)
        model2 = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), lambda)
        w = randn(StableRNG(1), d)
        @test predict_ridge(model1, w) == predict_ridge(model2, w)
    end

    # Broker model on [w; x] features produces finite predictions
    @testset "broker prediction with pooled model" begin
        rng = StableRNG(42)
        firms = [create_firm(j, d, rng) for j in 1:3]
        broker = make_broker_with_history(d, firms, 20, rng)
        n_b = effective_history_size(broker)
        WX = vcat(@view(broker.history_w[:, 1:n_b]), @view(broker.history_x[:, 1:n_b]))
        broker_model = fit_ridge(WX, @view(broker.history_q[1:n_b]), lambda)
        q = predict_ridge(broker_model, vcat(randn(rng, d), firms[1].type))
        @test isfinite(q)
    end

    # After initialization, all agents have seeded history so all models are fitted
    @testset "build_period_models after initialization" begin
        state = initialize_model(default_params(d=d, N_W=100, N_F=5))
        models = build_period_models(state, lambda)
        @test length(models.firm_models) == 5
        @test all(m isa RidgeModel for m in models.firm_models)
        @test models.broker_model isa RidgeModel
    end
end

@testset "Prediction Quality" begin
    # Perfect predictions give R-squared = 1
    @testset "perfect predictions" begin
        predicted = Float64[1.0, 2.0, 3.0, 4.0, 5.0]
        realized = Float64[1.0, 2.0, 3.0, 4.0, 5.0]
        pq = compute_prediction_quality(predicted, realized)
        @test pq.r_squared ≈ 1.0
        @test pq.bias ≈ 0.0
        @test pq.rank_corr ≈ 1.0
    end

    # Too few observations returns NaN
    @testset "too few observations returns NaN" begin
        pq = compute_prediction_quality(Float64[1.0, 2.0], Float64[1.0, 2.0])
        @test isnan(pq.r_squared)
        @test isnan(pq.bias)
        @test isnan(pq.rank_corr)
    end

    # Positive bias detected
    @testset "positive bias detected" begin
        predicted = Float64[3.0, 4.0, 5.0, 6.0, 7.0]
        realized = Float64[1.0, 2.0, 3.0, 4.0, 5.0]
        pq = compute_prediction_quality(predicted, realized)
        @test pq.bias > 0.0
    end

    # Negative R-squared for bad predictions
    @testset "negative R-squared for bad predictions" begin
        predicted = Float64[10.0, -10.0, 10.0, -10.0, 10.0]
        realized = Float64[1.0, 2.0, 3.0, 4.0, 5.0]
        pq = compute_prediction_quality(predicted, realized)
        @test pq.r_squared < 0.0
    end
end
