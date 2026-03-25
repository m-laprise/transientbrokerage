using Test
using TransientBrokerage
using StableRNGs: StableRNG
using NearestNeighbors: KDTree

# Build a minimal state with history so predictions are meaningful
function make_search_state(; seed=42)
    params = default_params(d=4, s=1, N_W=100, N_F=10, seed=seed)
    state = initialize_model(params)
    # Give each firm some synthetic history
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
    k = 10
    cache = PredictionCache(k)

    # Internal search with empty referral pool should still find candidates from general pool
    @testset "internal search with empty referral pool" begin
        state = make_search_state()
        firm = state.firms[1]
        empty!(firm.referral_pool)
        avail = Set(w.id for w in state.workers if w.status == available)
        tree = KDTree(@view firm.history_w[:, 1:firm.history_count])
        accum = PeriodAccumulators()
        wid, q_hat = internal_search(firm, state.workers, avail, accum,
                                      state.params, state.cal.q_pub,
                                      state.rng, tree, cache)
        # Should find someone (or return 0 if surplus negative)
        @test wid == 0 || wid in avail
    end

    # When all candidates have low predicted output, search returns 0
    @testset "internal search respects surplus threshold" begin
        state = make_search_state()
        firm = state.firms[1]
        # Set all workers to have very high reservation wages
        for w in state.workers
            w.reservation_wage = 1e6
        end
        avail = Set(w.id for w in state.workers if w.status == available)
        tree = KDTree(@view firm.history_w[:, 1:firm.history_count])
        accum = PeriodAccumulators()
        wid, _ = internal_search(firm, state.workers, avail, accum,
                                  state.params, state.cal.q_pub,
                                  StableRNG(99), tree, cache)
        @test wid == 0
    end

    # Internal search should push confidence byproducts to accumulators
    @testset "internal search records confidence byproducts" begin
        state = make_search_state()
        firm = state.firms[1]
        avail = Set(w.id for w in state.workers if w.status == available)
        tree = KDTree(@view firm.history_w[:, 1:firm.history_count])
        accum = PeriodAccumulators()
        internal_search(firm, state.workers, avail, accum,
                        state.params, state.cal.q_pub, StableRNG(1), tree, cache)
        @test length(accum.firm_mean_dists) > 0
        @test isempty(accum.broker_mean_dists)
    end

    # Broker allocate with empty pool returns nothing
    @testset "broker_allocate! with empty pool" begin
        state = make_search_state()
        empty!(state.broker.pool)
        clients = [(1, state.firms[1])]
        avail = Set(w.id for w in state.workers if w.status == available)
        trees = build_period_trees(state, [1])
        accum = PeriodAccumulators()
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   accum, state.params, state.cal.q_pub,
                                   StableRNG(1), trees, cache)
        @test isempty(result)
    end

    # Broker allocate with one client returns at most one assignment
    @testset "broker_allocate! with one client" begin
        state = make_search_state()
        # Give broker some history
        rng = StableRNG(77)
        for _ in 1:30
            w = clamp.(randn(rng, d), -3.0, 3.0)
            state.broker.history_count += 1
            idx = state.broker.history_count
            state.broker.history_w[:, idx] = w
            state.broker.history_x[:, idx] = state.firms[1].type
            state.broker.history_q[idx] = sum(w .* state.firms[1].type)
            state.broker.history_firm_idx[idx] = 1
        end
        clients = [(1, state.firms[1])]
        avail = Set(w.id for w in state.workers if w.status == available)
        trees = build_period_trees(state, [1])
        accum = PeriodAccumulators()
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   accum, state.params, state.cal.q_pub,
                                   StableRNG(1), trees, cache)
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
        trees = build_period_trees(state, [1])
        accum = PeriodAccumulators()
        result = broker_allocate!(state.broker, clients, state.workers, avail,
                                   accum, state.params, state.cal.q_pub,
                                   StableRNG(1), trees, cache)
        @test isempty(result)
    end

    # Broker allocate records confidence byproducts
    @testset "broker_allocate! records confidence byproducts" begin
        state = make_search_state()
        rng = StableRNG(77)
        for _ in 1:30
            w = clamp.(randn(rng, d), -3.0, 3.0)
            state.broker.history_count += 1
            idx = state.broker.history_count
            state.broker.history_w[:, idx] = w
            state.broker.history_x[:, idx] = state.firms[1].type
            state.broker.history_q[idx] = sum(w .* state.firms[1].type)
            state.broker.history_firm_idx[idx] = 1
        end
        clients = [(1, state.firms[1])]
        avail = Set(w.id for w in state.workers if w.status == available)
        trees = build_period_trees(state, [1])
        accum = PeriodAccumulators()
        broker_allocate!(state.broker, clients, state.workers, avail,
                          accum, state.params, state.cal.q_pub,
                          StableRNG(1), trees, cache)
        @test length(accum.broker_mean_dists) > 0
        @test isempty(accum.firm_mean_dists)
    end
end
