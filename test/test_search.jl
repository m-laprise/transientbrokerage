using Test
using TransientBrokerage
using StableRNGs: StableRNG

# Build a minimal state with history so ridge models can be fitted
function make_search_state(; seed=42)
    params = default_params(d=4, N_W=100, N_F=10, seed=seed)
    state = initialize_model(params)
    rng = StableRNG(seed + 1)
    for firm in state.firms
        for _ in 1:20
            w = randn(rng, params.d)
            firm.history_count += 1
            firm.history_w[:, firm.history_count] = w
            firm.history_q[firm.history_count] = sum(w .* firm.type)
        end
    end
    return state
end

@testset "Search" begin
    d = 4
    lambda = 1.0

    # Internal search with empty referral pool should still find candidates
    @testset "internal search with empty referral pool" begin
        state = make_search_state()
        firm = state.firms[1]
        empty!(firm.referral_pool)
        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        models = build_period_models(state, lambda)
        wid, q_hat = internal_search(firm, state.workers, avail,
                                      state.params,
                                      state.rng, models.firm_models[1])
        @test wid == 0 || avail[wid]
    end

    # When all candidates have very high reservation wages, search returns 0
    @testset "internal search respects surplus threshold" begin
        state = make_search_state()
        firm = state.firms[1]
        for w in state.workers
            w.reservation_wage = 1e6
        end
        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        models = build_period_models(state, lambda)
        wid, _ = internal_search(firm, state.workers, avail,
                                  state.params,
                                  StableRNG(99), models.firm_models[1])
        @test wid == 0
    end

    # Broker allocate with empty pool returns nothing
    @testset "broker_allocate! with empty pool" begin
        state = make_search_state()
        empty!(state.broker.pool)
        clients = [(1, state.firms[1])]
        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        models = build_period_models(state, lambda)
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   state.params,
                                   StableRNG(1), models)
        @test isempty(result)
    end

    # Broker allocate with one client returns at most one assignment
    @testset "broker_allocate! with one client" begin
        state = make_search_state()
        rng = StableRNG(77)
        for _ in 1:30
            w = randn(rng, d)
            record_broker_history!(state.broker, w, state.firms[1].type, 1,
                                   sum(w .* state.firms[1].type))
        end
        clients = [(1, state.firms[1])]
        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        models = build_period_models(state, lambda)
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   state.params,
                                   StableRNG(1), models)
        @test length(result) <= 1
        if !isempty(result)
            firm_idx, wid, q_hat = result[1]
            @test firm_idx == 1
            @test wid in state.broker.pool
        end
    end

    # Broker allocate respects surplus threshold
    @testset "broker_allocate! respects surplus threshold" begin
        state = make_search_state()
        for w in state.workers
            w.reservation_wage = 1e6
        end
        clients = [(1, state.firms[1])]
        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        models = build_period_models(state, lambda)
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   state.params,
                                   StableRNG(1), models)
        @test isempty(result)
    end

    # internal_search selects the higher-quality worker
    @testset "internal_search picks best candidate" begin
        state = make_search_state()
        firm = state.firms[1]
        # Make all workers unavailable except two
        avail = falses(length(state.workers))
        # Worker 1: type aligned with firm (high predicted quality)
        state.workers[1].type .= firm.type
        state.workers[1].reservation_wage = 0.0
        avail[1] = true
        # Worker 2: type orthogonal to firm (low predicted quality)
        state.workers[2].type .= 0.0
        state.workers[2].reservation_wage = 0.0
        avail[2] = true
        # Seed firm history with observations that reward alignment
        firm.history_count = 0
        rng = StableRNG(77)
        for _ in 1:50
            w = firm.type .+ 0.1 .* randn(rng, 4)
            q = sum(w .* firm.type)  # high q for aligned types
            record_history!(firm, w, q)
        end
        models = build_period_models(state, 1.0)
        wid, _ = internal_search(firm, state.workers, avail,
                                  state.params, StableRNG(1), models.firm_models[1])
        @test wid == 1  # aligned worker chosen
    end

    # broker_allocate! selects the higher-quality worker
    @testset "broker_allocate! picks best candidate" begin
        state = make_search_state()
        firm = state.firms[1]
        # Set up broker pool with two workers: one good, one bad
        empty!(state.broker.pool)
        state.workers[1].type .= firm.type
        state.workers[1].status = available
        state.workers[1].reservation_wage = 0.0
        push!(state.broker.pool, 1)
        state.workers[2].type .= 0.0
        state.workers[2].status = available
        state.workers[2].reservation_wage = 0.0
        push!(state.broker.pool, 2)
        avail = falses(length(state.workers))
        avail[1] = true; avail[2] = true
        # Seed broker history to reward alignment with firm type
        state.broker.history_count = 0
        rng = StableRNG(88)
        for _ in 1:50
            w = firm.type .+ 0.1 .* randn(rng, 4)
            q = sum(w .* firm.type)
            record_broker_history!(state.broker, w, firm.type, 1, q)
        end
        models = build_period_models(state, 1.0)
        clients = [(1, firm)]
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   state.params, StableRNG(1), models)
        @test length(result) == 1
        _, wid, _ = result[1]
        @test wid == 1  # aligned worker chosen
    end

    # Buffer optimization in broker_allocate! produces correct predictions
    @testset "broker_allocate! buffer matches vcat prediction" begin
        state = make_search_state()
        rng = StableRNG(77)
        for _ in 1:30
            w = randn(rng, d)
            record_broker_history!(state.broker, w, state.firms[1].type, 1,
                                   sum(w .* state.firms[1].type))
        end
        models = build_period_models(state, lambda)
        wid = first(state.broker.pool)
        w = state.workers[wid].type
        x = state.firms[1].type
        # Via broker_features (allocating)
        q_alloc = predict_ridge(models.broker_model, broker_features(w, x))
        # Via predict_ridge! (buffer, what broker_allocate! uses internally)
        buf = Vector{Float64}(undef, broker_feature_dim(d))
        q_buf = predict_ridge!(models.broker_model, buf, w, x)
        @test q_alloc ≈ q_buf
    end
end
