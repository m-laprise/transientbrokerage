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
            w = clamp.(randn(rng, params.d), -3.0, 3.0)
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
        avail = Set(w.id for w in state.workers if w.status == available)
        models = build_period_models(state, lambda)
        wid, q_hat = internal_search(firm, state.workers, avail,
                                      state.params,
                                      state.rng, models.firm_models[1])
        @test wid == 0 || wid in avail
    end

    # When all candidates have very high reservation wages, search returns 0
    @testset "internal search respects surplus threshold" begin
        state = make_search_state()
        firm = state.firms[1]
        for w in state.workers
            w.reservation_wage = 1e6
        end
        avail = Set(w.id for w in state.workers if w.status == available)
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
        avail = Set(w.id for w in state.workers if w.status == available)
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
            w = clamp.(randn(rng, d), -3.0, 3.0)
            record_broker_history!(state.broker, w, state.firms[1].type, 1,
                                   sum(w .* state.firms[1].type))
        end
        clients = [(1, state.firms[1])]
        avail = Set(w.id for w in state.workers if w.status == available)
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
        avail = Set(w.id for w in state.workers if w.status == available)
        models = build_period_models(state, lambda)
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   state.params,
                                   StableRNG(1), models)
        @test isempty(result)
    end

    # Buffer optimization in broker_allocate! produces correct predictions
    @testset "broker_allocate! buffer matches vcat prediction" begin
        state = make_search_state()
        rng = StableRNG(77)
        for _ in 1:30
            w = clamp.(randn(rng, d), -3.0, 3.0)
            record_broker_history!(state.broker, w, state.firms[1].type, 1,
                                   sum(w .* state.firms[1].type))
        end
        models = build_period_models(state, lambda)
        wid = first(state.broker.pool)
        w = state.workers[wid].type
        x = state.firms[1].type
        # Via vcat
        q_vcat = predict_ridge(models.broker_model, broker_features(w, x))
        # Via pre-filled buffer (what broker_allocate! does internally)
        buf = Vector{Float64}(undef, 4d)
        buf[1:d] .= w
        buf[d+1:2d] .= x
        @views buf[2d+1:3d] .= buf[1:d] .* buf[d+1:2d]
        @views buf[3d+1:4d] .= buf[1:d] .^ 2
        q_buf = predict_ridge(models.broker_model, buf)
        @test q_vcat == q_buf
    end
end
