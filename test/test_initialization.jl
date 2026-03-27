using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Graphs: nv, is_connected

@testset "Initialization" begin
    params = default_params()
    state = initialize_model(params)

    @testset "initialize_model returns valid ModelState" begin
        @test state isa ModelState
        @test state.env isa MatchingEnv
        @test state.cal isa CalibrationConstants
        @test state.period == 0
    end

    @testset "calibration constants are positive" begin
        @test state.cal.r_base > 0
        @test state.cal.f_bar > 0
        @test isfinite(state.cal.q_pub)
        @test state.cal.q_pub != state.cal.f_bar  # q_pub = E[f], f_bar = E[|f|]
        @test state.cal.r_base ≈ 0.70 * state.cal.f_bar
    end

    @testset "correct agent counts" begin
        @test length(state.workers) == params.N_W
        @test length(state.firms) == params.N_F
    end

    @testset "worker properties" begin
        @test all(1 <= w.node_id <= params.N_W for w in state.workers)
        @test all(all(-3.0 .<= w.type .<= 3.0) for w in state.workers)
        @test all(length(w.type) == params.d for w in state.workers)
    end

    @testset "firm properties" begin
        @test all(all(-3.0 .<= f.type .<= 3.0) for f in state.firms)
        @test all(length(f.type) == params.d for f in state.firms)
    end

    @testset "initial employment: 3-5 per firm, no double-counting" begin
        @test all(3 <= length(f.employees) <= 5 for f in state.firms)
        all_employed = reduce(union, (f.employees for f in state.firms))
        total_assigned = sum(length(f.employees) for f in state.firms)
        @test length(all_employed) == total_assigned
    end

    @testset "worker status consistent with employment" begin
        employed_ids = reduce(union, (f.employees for f in state.firms))
        @test all(w.status == employed && w.employer_id > 0
                  for w in state.workers if w.id in employed_ids)
        @test all(w.status == available && w.employer_id == 0
                  for w in state.workers if w.id ∉ employed_ids)
    end

    @testset "reservation wages >= r_base" begin
        @test all(w.reservation_wage >= state.cal.r_base for w in state.workers)
    end

    @testset "compute_reservation_wage keyword args change behavior" begin
        rng1 = StableRNG(1)
        rng2 = StableRNG(1)
        r1 = compute_reservation_wage(3, 10, 1.0, rng1; network_premium=0.20)
        r2 = compute_reservation_wage(3, 10, 1.0, rng2; network_premium=0.50)
        @test r1 != r2
    end

    @testset "broker" begin
        expected_pool = ceil(Int, params.pool_target_frac * params.N_W)
        @test length(state.broker.pool) == expected_pool
        @test all(state.workers[wid].status == available for wid in state.broker.pool)
        @test state.broker.last_reputation == state.cal.q_pub
        @test size(state.broker.history_w) == (params.d, 5000)
        @test size(state.broker.history_x) == (params.d, 5000)
        @test length(state.broker.history_q) == 5000
        @test length(state.broker.history_firm_idx) == 5000
        @test state.broker.history_count == 0
    end

    @testset "firm history and satisfaction" begin
        @test all(size(f.history_w) == (params.d, 200) for f in state.firms)
        @test all(length(f.history_q) == 200 for f in state.firms)
        @test all(f.history_count == 0 for f in state.firms)
        @test all(f.satisfaction_internal == state.cal.q_pub for f in state.firms)
        @test all(f.satisfaction_broker == state.cal.q_pub for f in state.firms)
    end

    @testset "social network has correct size" begin
        @test nv(state.G_S) == params.N_W
    end

    @testset "deterministic with fixed seed" begin
        s2 = initialize_model(params)
        @test state.cal.r_base == s2.cal.r_base
        @test state.cal.f_bar == s2.cal.f_bar
        @test state.workers[1].type == s2.workers[1].type
        @test state.workers[1].reservation_wage == s2.workers[1].reservation_wage
        @test state.firms[1].type == s2.firms[1].type
    end

    @testset "next_firm_id set correctly" begin
        @test state.next_firm_id == params.N_F + 1
    end
end
