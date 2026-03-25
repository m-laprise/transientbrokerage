using Test
using TransientBrokerage
using StableRNGs: StableRNG
using NearestNeighbors: KDTree
using Statistics: mean

# Create a firm with n_obs synthetic history entries using dot-product output
function make_firm_with_history(d::Int, n_obs::Int, rng::StableRNG)
    firm = create_firm(1, d, rng)
    for i in 1:n_obs
        w = clamp.(randn(rng, d), -3.0, 3.0)
        firm.history_count += 1
        firm.history_w[:, firm.history_count] = w
        firm.history_q[firm.history_count] = sum(w .* firm.type)
    end
    return firm
end

# Create a broker with cross-firm history using additive mu + interaction structure
function make_broker_with_history(d::Int, firms::Vector{Firm}, n_per_firm::Int,
                                   rng::StableRNG; cap::Int=5000)
    broker = Broker(id=1,
                    history_w=Matrix{Float64}(undef, d, cap),
                    history_x=Matrix{Float64}(undef, d, cap),
                    history_q=Vector{Float64}(undef, cap),
                    history_firm_idx=Vector{Int}(undef, cap))
    for (j, firm) in enumerate(firms)
        for _ in 1:n_per_firm
            w = clamp.(randn(rng, d), -3.0, 3.0)
            q = sum(w) * 0.5 + sum(w .* firm.type) * 0.5
            broker.history_count += 1
            idx = broker.history_count
            broker.history_w[:, idx] = w
            broker.history_x[:, idx] = firm.type
            broker.history_q[idx] = q
            broker.history_firm_idx[idx] = j
        end
    end
    return broker
end

@testset "Learning" begin
    d = 4
    k = 10
    cache = PredictionCache(k)

    # With no history, prediction should fall back to the public benchmark
    @testset "empty history defaults to q_pub" begin
        firm = create_firm(1, d, StableRNG(1))
        result = predict_firm(firm, randn(StableRNG(2), d), 5.0, k, nothing, cache)
        @test result.q_hat == 5.0
        @test result.mean_dist == Inf
        @test isnan(result.neighbor_var)
    end

    # With one observation, querying at that exact point should return its output
    @testset "single observation returns that output" begin
        firm = create_firm(1, d, StableRNG(1))
        w1 = randn(StableRNG(3), d)
        firm.history_count = 1
        firm.history_w[:, 1] = w1
        firm.history_q[1] = 7.5
        tree = KDTree(@view firm.history_w[:, 1:1])
        result = predict_firm(firm, w1, 0.0, k, tree, cache)
        @test result.q_hat ≈ 7.5
        @test result.neighbor_var == 0.0
    end

    # Gaussian kernel should weight nearer neighbors more heavily
    @testset "distance weighting: nearer observation has stronger influence" begin
        firm = create_firm(1, d, StableRNG(1))
        firm.history_count = 2
        firm.history_w[:, 1] = zeros(d)       # near origin, output = 10
        firm.history_q[1] = 10.0
        firm.history_w[:, 2] = ones(d) * 3.0  # far from origin, output = 0
        firm.history_q[2] = 0.0
        tree = KDTree(@view firm.history_w[:, 1:2])
        result = predict_firm(firm, zeros(d), 5.0, k, tree, cache)
        @test result.q_hat > 5.0
    end

    # Prediction error should decrease as the firm accumulates more history
    @testset "learning curve: RMSE decreases with more observations" begin
        rmses = Float64[]
        for n_obs in [5, 20, 50, 100]
            errors = Float64[]
            for seed in 1:10
                rng = StableRNG(seed)
                firm = make_firm_with_history(d, n_obs, rng)
                tree = KDTree(@view firm.history_w[:, 1:firm.history_count])
                for _ in 1:20
                    w_test = clamp.(randn(rng, d), -3.0, 3.0)
                    q_true = sum(w_test .* firm.type)
                    q_hat = predict_firm(firm, w_test, 0.0, k, tree, cache).q_hat
                    push!(errors, (q_hat - q_true)^2)
                end
            end
            push!(rmses, sqrt(mean(errors)))
        end
        @test rmses[end] < rmses[1]
    end

    # Two-stage decomposition should outperform single-firm prediction
    # when the broker pools data across multiple firms
    @testset "broker decomposition advantage" begin
        rng = StableRNG(42)
        n_firms = 5
        firms = [create_firm(j, d, rng) for j in 1:n_firms]
        broker = make_broker_with_history(d, firms, 40, rng)

        state = initialize_model(default_params(d=d, s=1, N_W=100, N_F=n_firms))
        state_mock = ModelState(params=state.params, rng=state.rng, env=state.env,
                                cal=state.cal, workers=state.workers,
                                firms=firms, broker=broker, G_S=state.G_S,
                                next_firm_id=n_firms+1,
                                cached_network=state.cached_network)
        trees = build_period_trees(state_mock, collect(1:n_firms))

        broker_errors = Float64[]
        firm_errors = Float64[]
        rng2 = StableRNG(99)
        for j in 1:n_firms
            firm = firms[j]
            firm_tree = trees.firm_trees[j]
            for _ in 1:20
                w_test = clamp.(randn(rng2, d), -3.0, 3.0)
                q_true = sum(w_test) * 0.5 + sum(w_test .* firm.type) * 0.5
                push!(broker_errors, (predict_broker(broker, w_test, j, 0.0, k, trees, cache).q_hat - q_true)^2)
                push!(firm_errors, (predict_firm(firm, w_test, 0.0, k, firm_tree, cache).q_hat - q_true)^2)
            end
        end
        @test sqrt(mean(broker_errors)) < sqrt(mean(firm_errors))
    end

    # With enough cross-firm data, Stage 1 should recover the worker-general component
    @testset "Stage 1 convergence" begin
        rng = StableRNG(42)
        firms = [create_firm(j, d, rng) for j in 1:3]
        broker = make_broker_with_history(d, firms, 200, rng)
        tree = KDTree(@view broker.history_w[:, 1:broker.history_count])
        rng2 = StableRNG(99)
        errors = Float64[]
        for _ in 1:50
            w = clamp.(randn(rng2, d), -3.0, 3.0)
            mu_true = sum(w) * 0.5
            mu_hat = TransientBrokerage._predict_stage1(broker, w, 0.0, k, tree, cache)
            push!(errors, (mu_hat - mu_true)^2)
        end
        @test sqrt(mean(errors)) < 1.0
    end

    # Dense local data should yield smaller mean_dist (epistemic uncertainty)
    @testset "confidence byproducts: dense vs sparse" begin
        rng = StableRNG(42)
        firm_dense = create_firm(1, d, rng)
        for i in 1:50
            w = randn(rng, d) * 0.1
            firm_dense.history_count += 1
            firm_dense.history_w[:, firm_dense.history_count] = w
            firm_dense.history_q[firm_dense.history_count] = 1.0
        end
        tree_dense = KDTree(@view firm_dense.history_w[:, 1:firm_dense.history_count])
        result_dense = predict_firm(firm_dense, zeros(d), 0.0, k, tree_dense, cache)

        firm_sparse = create_firm(2, d, rng)
        for i in 1:5
            w = randn(rng, d) * 3.0
            firm_sparse.history_count += 1
            firm_sparse.history_w[:, firm_sparse.history_count] = w
            firm_sparse.history_q[firm_sparse.history_count] = 1.0
        end
        tree_sparse = KDTree(@view firm_sparse.history_w[:, 1:firm_sparse.history_count])
        result_sparse = predict_firm(firm_sparse, zeros(d), 0.0, k, tree_sparse, cache)

        @test result_dense.mean_dist < result_sparse.mean_dist
    end

    # k-NN is deterministic given the same inputs
    @testset "deterministic with fixed seed" begin
        firm = make_firm_with_history(d, 20, StableRNG(42))
        tree = KDTree(@view firm.history_w[:, 1:firm.history_count])
        w = randn(StableRNG(1), d)
        r1 = predict_firm(firm, w, 0.0, k, tree, PredictionCache(k))
        r2 = predict_firm(firm, w, 0.0, k, tree, PredictionCache(k))
        @test r1.q_hat == r2.q_hat
        @test r1.mean_dist == r2.mean_dist
        @test r1.neighbor_var == r2.neighbor_var
    end

    # Wrapper should return q_hat and push byproducts to the correct accumulator vectors
    @testset "predict_and_record_firm! pushes to accumulators" begin
        firm = make_firm_with_history(d, 20, StableRNG(42))
        tree = KDTree(@view firm.history_w[:, 1:firm.history_count])
        accum = PeriodAccumulators()
        w = randn(StableRNG(1), d)
        q_hat = predict_and_record_firm!(accum, firm, w, 0.0, k, tree, cache)
        @test isfinite(q_hat)
        @test length(accum.firm_mean_dists) == 1
        @test length(accum.firm_neighbor_vars) == 1
        @test isempty(accum.broker_mean_dists)
    end

    # Broker record wrapper should push to broker accumulator vectors, not firm vectors
    @testset "predict_and_record_broker! pushes to accumulators" begin
        rng = StableRNG(42)
        n_firms = 3
        firms = [create_firm(j, d, rng) for j in 1:n_firms]
        broker = make_broker_with_history(d, firms, 20, rng)
        state = initialize_model(default_params(d=d, s=1, N_W=100, N_F=n_firms))
        state_mock = ModelState(params=state.params, rng=state.rng, env=state.env,
                                cal=state.cal, workers=state.workers,
                                firms=firms, broker=broker, G_S=state.G_S,
                                next_firm_id=n_firms+1,
                                cached_network=state.cached_network)
        trees = build_period_trees(state_mock, collect(1:n_firms))
        accum = PeriodAccumulators()
        w = randn(StableRNG(1), d)
        q_hat = predict_and_record_broker!(accum, broker, w, 1, 0.0, k, trees, cache)
        @test isfinite(q_hat)
        @test length(accum.broker_mean_dists) == 1
        @test length(accum.broker_neighbor_vars) == 1
        @test isempty(accum.firm_mean_dists)
    end

    # Broker with empty history should fall back to q_pub
    @testset "broker empty history defaults to q_pub" begin
        broker = Broker(id=1,
                        history_w=Matrix{Float64}(undef, d, 100),
                        history_x=Matrix{Float64}(undef, d, 100),
                        history_q=Vector{Float64}(undef, 100),
                        history_firm_idx=Vector{Int}(undef, 100))
        empty_trees = PeriodTrees(
            Vector{Union{Nothing, KDTree}}(nothing, 1),
            nothing,
            Dict{Int, KDTree}(),
            Dict{Int, Vector{Float64}}())
        result = predict_broker(broker, randn(StableRNG(1), d), 1, 5.0, k, empty_trees, cache)
        @test result.q_hat == 5.0
    end

    # When broker has Stage 1 data but no firm-specific Stage 2 data,
    # prediction should reduce to Stage 1 (zero residual)
    @testset "Stage 2 fallback to zero residual for unknown firm" begin
        rng = StableRNG(42)
        firms = [create_firm(j, d, rng) for j in 1:2]
        broker = make_broker_with_history(d, firms, 30, rng)
        state = initialize_model(default_params(d=d, s=1, N_W=100, N_F=2))
        state_mock = ModelState(params=state.params, rng=state.rng, env=state.env,
                                cal=state.cal, workers=state.workers,
                                firms=firms, broker=broker, G_S=state.G_S,
                                next_firm_id=3,
                                cached_network=state.cached_network)
        # Only build trees for firm 1, then query for firm 99 (unknown)
        trees = build_period_trees(state_mock, [1])
        w = randn(StableRNG(1), d)
        result_known = predict_broker(broker, w, 1, 0.0, k, trees, cache)
        result_unknown = predict_broker(broker, w, 99, 0.0, k, trees, cache)
        # Unknown firm gets Stage 1 only (mu_hat + 0), so q_hat == mu_hat
        mu_hat = TransientBrokerage._predict_stage1(
            broker, w, 0.0, k, trees.broker_s1_tree, cache)
        @test result_unknown.q_hat ≈ mu_hat
        @test result_unknown.mean_dist == Inf
    end

    # build_period_trees with empty histories should return all-nothing trees
    @testset "build_period_trees with empty histories" begin
        state = initialize_model(default_params(d=d, s=1, N_W=100, N_F=5))
        trees = build_period_trees(state, Int[])
        @test all(t === nothing for t in trees.firm_trees)
        @test trees.broker_s1_tree === nothing
        @test isempty(trees.broker_s2_trees)
        @test isempty(trees.broker_s2_residuals)
    end
end

@testset "Prediction Quality" begin
    # Perfect predictions should give R-squared=1, zero bias, perfect rank correlation
    @testset "perfect predictions" begin
        realized = collect(1.0:10.0)
        pq = compute_prediction_quality(copy(realized), realized)
        @test pq.r_squared ≈ 1.0
        @test pq.bias ≈ 0.0 atol=1e-12
        @test pq.rank_corr ≈ 1.0
    end

    # Fewer than 5 observations should return NaN (insufficient data)
    @testset "too few observations returns NaN" begin
        pq = compute_prediction_quality([1.0, 2.0], [1.0, 2.0])
        @test isnan(pq.r_squared)
        @test isnan(pq.bias)
        @test isnan(pq.rank_corr)
    end

    # R-squared should be finite and well-defined at various sample sizes
    @testset "R-squared finite at various n" begin
        rng = StableRNG(42)
        r2_values = Float64[]
        for n in [10, 50, 200]
            realized = randn(rng, n)
            predicted = realized .+ randn(rng, n) * 0.5
            pq = compute_prediction_quality(predicted, realized)
            push!(r2_values, pq.r_squared)
        end
        @test all(isfinite, r2_values)
    end

    # A constant overestimate should be detected as positive bias
    @testset "positive bias detected" begin
        realized = collect(1.0:20.0)
        predicted = realized .+ 2.0
        pq = compute_prediction_quality(predicted, realized)
        @test pq.bias ≈ 2.0
    end

    # Random noise predictions should produce negative R-squared (worse than the mean)
    @testset "negative R-squared for bad predictions" begin
        rng = StableRNG(42)
        realized = randn(rng, 50)
        predicted = randn(rng, 50) * 10.0  # uncorrelated noise, much larger scale
        pq = compute_prediction_quality(predicted, realized)
        @test pq.r_squared < 0.0
    end
end
