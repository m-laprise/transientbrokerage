using Test
using TransientBrokerage
using StableRNGs: StableRNG
using LinearAlgebra: normalize, norm

@testset "Neural Network Learning" begin

    @testset "predict_nn! produces finite output" begin
        rng = StableRNG(42)
        nn = init_neural_net(8, 16, rng)
        buf = zeros(16)
        z = randn(rng, 8)
        y = predict_nn!(nn, buf, z)
        @test isfinite(y)
    end

    @testset "predict_nn! is deterministic" begin
        rng = StableRNG(42)
        nn = init_neural_net(8, 16, rng)
        buf = zeros(16)
        z = randn(StableRNG(1), 8)
        y1 = predict_nn!(nn, buf, z)
        y2 = predict_nn!(nn, buf, z)
        @test y1 == y2
    end

    @testset "nn_loss is finite and positive" begin
        rng = StableRNG(42)
        nn = init_neural_net(8, 16, rng)
        X = randn(rng, 8, 10)
        q = randn(rng, 10)
        loss = nn_loss(nn.W1, nn.b1, nn.w2, Ref(nn.b2), X, q)
        @test isfinite(loss)
        @test loss > 0.0
    end

    @testset "Training reduces loss" begin
        rng = StableRNG(42)
        nn = init_neural_net(8, 16, rng)
        grad = NNGradBuffers(nn)
        X = randn(StableRNG(1), 8, 20)
        q = randn(StableRNG(2), 20)

        loss_before = nn_loss(nn.W1, nn.b1, nn.w2, Ref(nn.b2), X, q)
        train_nn!(nn, grad, X, q, 50, 0.01)
        loss_after = nn_loss(nn.W1, nn.b1, nn.w2, Ref(nn.b2), X, q)

        @test loss_after < loss_before
    end

    @testset "NN can learn a linear function" begin
        rng = StableRNG(42)
        d = 8
        nn = init_neural_net(d, 16, rng)
        grad = NNGradBuffers(nn)

        n = 100
        X = randn(StableRNG(1), d, n)
        q = [2.0 * X[1, j] + 0.5 * X[2, j] + 1.0 for j in 1:n]

        train_nn!(nn, grad, X, Vector{Float64}(q), 200, 0.01)

        X_test = randn(StableRNG(99), d, 20)
        q_test = [2.0 * X_test[1, j] + 0.5 * X_test[2, j] + 1.0 for j in 1:20]
        buf = zeros(16)
        preds = [predict_nn!(nn, buf, X_test[:, j]) for j in 1:20]
        mse = sum((preds .- q_test).^2) / 20
        @test mse < 0.5
    end

    @testset "Adaptive step schedule" begin
        @test compute_adaptive_steps(100, 5, 5) == 100     # all new
        @test compute_adaptive_steps(100, 3, 5) == 60      # 3 of 5 new (above floor)
        @test compute_adaptive_steps(100, 1, 50) == 50     # floor at ADAPTIVE_FLOOR=50
        @test compute_adaptive_steps(100, 1, 200) == 50    # floor
        @test compute_adaptive_steps(100, 0, 100) >= 50    # floor
        @test compute_adaptive_steps(100, 1, 0) == 100     # empty history
    end

    @testset "train_agent_nn! resets n_new_obs" begin
        rng = StableRNG(42)
        p = default_params(N=20)
        nn = init_neural_net(p.d, p.h_a, rng)
        agent = Agent(
            id=1, type=normalize(randn(rng, p.d)),
            history_X=randn(rng, p.d, 16), history_q=randn(rng, 16),
            history_count=5, n_new_obs=5,
            nn=nn, nn_grad=NNGradBuffers(nn), predict_buf=zeros(p.h_a),
            partner_sum=zeros(20), partner_count=zeros(Int, 20),
        )
        train_agent_nn!(agent, p)
        @test agent.n_new_obs == 0
    end

    @testset "train_agent_nn! with empty history is no-op" begin
        rng = StableRNG(42)
        p = default_params(N=20)
        nn = init_neural_net(p.d, p.h_a, rng)
        w1_before = copy(nn.W1)
        agent = Agent(
            id=1, type=normalize(randn(rng, p.d)),
            history_X=Matrix{Float64}(undef, p.d, 16),
            history_q=Vector{Float64}(undef, 16),
            history_count=0, n_new_obs=0,
            nn=nn, nn_grad=NNGradBuffers(nn), predict_buf=zeros(p.h_a),
            partner_sum=zeros(20), partner_count=zeros(Int, 20),
        )
        train_agent_nn!(agent, p)
        @test agent.nn.W1 == w1_before
    end

    # Weight decay removed: the NN has no explicit L2 regularization. With MSE
    # targets of zero the weights still trend toward zero via pure gradient
    # descent, but that's a property of the optimization target, not of a
    # separate decay term. See scan results showing λ had no measurable effect
    # at tested scales; decay removed for simplicity.
end
