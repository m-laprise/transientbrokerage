using Test
using TransientBrokerage
using Graphs: SimpleGraph
using StableRNGs: StableRNG

@testset "Phase 0: Types and Parameters" begin
    # Verify @kwdef defaults and required fields for all agent structs
    @testset "Struct construction and field access" begin
        w = Worker(;
            id = 1,
            node_id = 1,
            type = zeros(8),
            reservation_wage = 1.0,
        )
        @test w.id == 1
        @test w.status == available
        @test w.employer_id == 0
        @test w.broker_id == 0
        @test w.staffing_firm_id == 0

        f = Firm(;
            id = 1,
            type = zeros(8),
            history_w = zeros(8, 100),
        )
        @test f.id == 1
        @test isempty(f.employees)
        @test f.history_count == 0
        @test f.satisfaction_internal == 0.0
        @test f.satisfaction_broker == 0.0
        @test f.hire_count == 0
        @test f.periods_alive == 0

        # StaffingAssignment uses positional args (no @kwdef)
        sa = StaffingAssignment(1, 1, 1, 4, zeros(8), zeros(8), 5.0, 3.0, 2.5)
        @test sa.worker_id == 1
        @test sa.periods_remaining == 4
        @test sa.bill_rate == 5.0

        b = Broker(;
            id = 1,
            history_w = zeros(8, 100),
            history_x = zeros(8, 100),
        )
        @test b.id == 1
        @test isempty(b.pool)
        @test b.history_count == 0
        @test b.last_reputation == 0.0
        @test b.has_had_clients == false
    end

    # MatchingEnv, CalibrationConstants, and CachedNetworkMeasures have correct dimensions
    @testset "Sub-struct construction" begin
        d, s = 8, 2
        env = MatchingEnv(
            zeros(d, d),
            zeros(d, s),
            zeros(s, d),
            [zeros(s)],
            zeros(1),
            1.0,
        )
        @test size(env.A) == (d, d)
        @test size(env.U) == (d, s)
        @test size(env.P) == (s, d)
        @test length(env.mu_centers) == 1
        @test env.mu_bandwidth == 1.0

        cal = CalibrationConstants(1.0, 2.0, 1.5)
        @test cal.r_base == 1.0
        @test cal.f_bar == 2.0
        @test cal.q_pub == 1.5

        cnm = CachedNetworkMeasures(Float64[], Float64[], Float64[])
        @test isempty(cnm.betweenness)
        @test isempty(cnm.constraint)
        @test isempty(cnm.effective_size)
    end

    # Params and environment are immutable; state containers are mutable
    @testset "Mutability contracts" begin
        # ModelParams is immutable
        @test !ismutable(default_params())

        # MatchingEnv and CalibrationConstants are immutable
        env = MatchingEnv(zeros(8, 8), zeros(8, 2), zeros(2, 8), [zeros(2)], zeros(1), 1.0)
        @test !ismutable(env)
        cal = CalibrationConstants(1.0, 1.0, 1.0)
        @test !ismutable(cal)

        # ModelState and PeriodAccumulators are mutable
        accum = PeriodAccumulators()
        @test ismutable(accum)
    end

    # Every baseline default matches the spec's table of values
    @testset "default_params returns valid ModelParams" begin
        p = default_params()
        @test p.d == 8
        @test p.s == 2
        @test p.rho == 0.50
        @test p.K_mu == 10
        @test p.N_W == 1000
        @test p.N_F == 100
        @test p.eta == 0.05
        @test p.beta_W == 0.50
        @test p.k_nn == 10
        @test p.k_S == 6
        @test p.p_rewire == 0.1
        @test p.omega == 0.3
        @test p.alpha == 0.20
        @test p.L == 4
        @test p.mu_b == 0.25
        @test p.c_emp_frac == 0.15
        @test p.p_vac == 0.10
        @test p.n_recruit_frac == 0.005
        @test p.n_candidates_frac == 0.01
        @test p.network_measure_interval == 10
        @test p.T == 200
        @test p.T_burn == 20
        @test p.seed == 42
    end

    # Keyword overrides replace defaults without affecting other fields
    @testset "default_params with overrides" begin
        p = default_params(; seed = 99, d = 10, s = 3)
        @test p.seed == 99
        @test p.d == 10
        @test p.s == 3
    end

    # Typos or invalid parameter names raise immediately
    @testset "default_params rejects unknown kwargs" begin
        @test_throws ErrorException default_params(; bogus_param = 42)
    end

    # Out-of-range or structurally invalid parameters throw AssertionError
    @testset "validate_params rejects invalid combinations" begin
        # d < 2s
        @test_throws AssertionError default_params(; d = 3, s = 2)
        # rho out of bounds
        @test_throws AssertionError default_params(; rho = -0.1)
        @test_throws AssertionError default_params(; rho = 1.5)
        # eta out of bounds
        @test_throws AssertionError default_params(; eta = 0.0)
        @test_throws AssertionError default_params(; eta = 1.0)
        # p_vac out of bounds
        @test_throws AssertionError default_params(; p_vac = 0.0)
        # alpha out of bounds
        @test_throws AssertionError default_params(; alpha = 0.0)
        # T_burn >= T
        @test_throws AssertionError default_params(; T = 10, T_burn = 10)
        # odd k_S
        @test_throws AssertionError default_params(; k_S = 5)
    end

    # Boundary values (rho=0, rho=1, d=2s) are valid and shouldn't throw
    @testset "validate_params accepts edge cases" begin
        # rho = 0 and rho = 1 are valid
        p0 = default_params(; rho = 0.0)
        @test p0.rho == 0.0
        p1 = default_params(; rho = 1.0)
        @test p1.rho == 1.0
        # d = 2s (minimum valid)
        p2 = default_params(; d = 4, s = 2)
        @test p2.d == 4
    end

    # Per-period fields zero out; cumulative revenue survives the reset
    @testset "reset_accumulators!" begin
        accum = PeriodAccumulators()
        # Set some per-period fields
        accum.matches = 10
        accum.new_staffing = 5
        accum.new_placements = 3
        push!(accum.q_direct, 1.0, 2.0)
        push!(accum.q_placed, 3.0)
        push!(accum.q_staffed, 4.0)
        accum.openings_internal = 7
        accum.openings_brokered = 8
        accum.placement_revenue = 100.0
        accum.staffing_revenue = 200.0
        push!(accum.firm_mean_dists, 1.0)
        push!(accum.broker_mean_dists, 2.0)
        # Set cumulative fields
        accum.cumulative_placement_revenue = 500.0
        accum.cumulative_staffing_revenue = 1000.0

        reset_accumulators!(accum)

        # Per-period fields are zeroed/emptied
        @test accum.matches == 0
        @test accum.new_staffing == 0
        @test accum.new_placements == 0
        @test isempty(accum.q_direct)
        @test isempty(accum.q_placed)
        @test isempty(accum.q_staffed)
        @test accum.openings_internal == 0
        @test accum.openings_brokered == 0
        @test accum.placement_revenue == 0.0
        @test accum.staffing_revenue == 0.0
        @test isempty(accum.firm_mean_dists)
        @test isempty(accum.broker_mean_dists)

        # Cumulative fields are preserved
        @test accum.cumulative_placement_revenue == 500.0
        @test accum.cumulative_staffing_revenue == 1000.0
    end

    # End-to-end: params validate, all sub-structs construct, accumulators reset cleanly
    @testset "Smoke test (Phase 0)" begin
        p = default_params()
        validate_params(p)

        # Sub-structs construct without error
        env = MatchingEnv(
            zeros(p.d, p.d),
            zeros(p.d, p.s),
            zeros(p.s, p.d),
            [zeros(p.s)],
            zeros(1),
            1.0,
        )
        cal = CalibrationConstants(1.0, 1.0, 1.0)
        accum = PeriodAccumulators()
        reset_accumulators!(accum)
        @test accum.matches == 0
    end
end
