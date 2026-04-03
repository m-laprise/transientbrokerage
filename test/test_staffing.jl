using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Statistics: mean

# Helper: get an available pool worker or error (never silently skip)
function get_avail_pool_worker(state)
    for wid in state.broker.pool
        state.workers[wid].status == available && return wid
    end
    error("No available worker in pool — test setup broken")
end

@testset "Staffing (Model 1)" begin

    # ── Decision functions ──

    @testset "broker_prefers_staffing" begin
        params = default_params(enable_staffing=true)
        r_base = 0.70  # typical calibrated value

        # At low q_hat_b, placement preferred (fee > staffing profit)
        @test !broker_prefers_staffing(0.5, 0.7, params, r_base)

        # At high q_hat_b, staffing preferred (L * mu_b * q >> alpha * wage)
        @test broker_prefers_staffing(3.0, 0.7, params, r_base)

        # Verify crossover: staffing profit = L*(mu_b*q - c_emp), placement = alpha*(r + beta_W*max(q-r,0))
        c_emp = params.c_emp_frac * r_base
        r_i = 0.7
        # For q > r_i: L*(mu_b*q - c_emp) = alpha*(r_i + beta_W*(q - r_i))
        # 4*(0.25q - 0.105) = 0.20*(0.7 + 0.5*(q - 0.7))
        # q - 0.42 = 0.14 + 0.1*(q - 0.7) = 0.14 + 0.1q - 0.07 = 0.07 + 0.1q
        # 0.9q = 0.49; q_cross ≈ 0.544
        # But at q=0.544, max(q-r_i,0) = max(-0.156,0) = 0 since q < r_i!
        # So for q < r_i: placement = alpha * r_i = 0.14 (constant)
        # Staffing = L*(mu_b*q - c_emp); solve: 4*(0.25q - 0.105) = 0.14
        # q - 0.42 = 0.14; q_cross = 0.56
        q_cross = 0.56
        @test !broker_prefers_staffing(q_cross - 0.02, r_i, params, r_base)
        @test broker_prefers_staffing(q_cross + 0.02, r_i, params, r_base)
    end

    @testset "firm_accepts_staffing" begin
        params = default_params(enable_staffing=true)
        r_i = 0.7

        # When q_hat_b ≈ q_hat_j, firm accepts because mu_b (0.25) < beta_W*(1+alpha/L) ≈ 0.525
        @test firm_accepts_staffing(1.5, 1.5, r_i, params)

        # Firm rejects when broker prediction much higher than firm's (bill rate too high)
        # bill = 0.7 + 0.25*5 = 1.95; direct = (0.7+0.5*0.3)*(1+0.2/4) = 0.85*1.05 = 0.8925
        @test !firm_accepts_staffing(5.0, 1.0, r_i, params)
        # Also verify a moderate gap still rejected
        @test !firm_accepts_staffing(3.0, 1.0, r_i, params)

        # Edge case: both predictions at reservation wage — firm rejects because
        # bill = r_i + mu_b*r_i > r_i*(1+alpha/L) = direct cost
        @test !firm_accepts_staffing(r_i, r_i, r_i, params)
    end

    # ── Lock-in invariants ──

    @testset "lock-in: firm history and employees unchanged" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        firm_idx = 1
        firm = state.firms[firm_idx]
        hist_before = firm.history_count
        empl_before = length(firm.employees)
        broker_hist_before = state.broker.history_count

        wid = get_avail_pool_worker(state)
        worker = state.workers[wid]
        pm = ProposedMatch(firm_idx, wid, :staffing, 1.5, 1.5, worker.reservation_wage)
        create_staffing_assignment!(state, pm, 1.5)

        # Lock-in: firm unchanged
        @test firm.history_count == hist_before
        @test length(firm.employees) == empl_before
        @test wid ∉ firm.employees

        # Worker is staffed
        @test worker.status == staffed
        @test worker.broker_id == state.broker.id
        @test worker.staffing_firm_id == firm.id

        # Broker history grew by 1
        @test state.broker.history_count == broker_hist_before + 1

        # Assignment created correctly
        sa = state.broker.active_assignments[end]
        @test sa.worker_id == wid
        @test sa.firm_idx == firm_idx
        @test sa.firm_id == firm.id
        @test sa.periods_remaining == params.L
    end

    @testset "satisfaction uses staffing cost, not placement cost" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        firm_idx = 1
        firm = state.firms[firm_idx]
        sat_before = firm.satisfaction_broker
        omega = params.omega

        wid = get_avail_pool_worker(state)
        r_i = state.workers[wid].reservation_wage
        q_hat_b = 1.5
        pm = ProposedMatch(firm_idx, wid, :staffing, 1.5, q_hat_b, r_i)
        q = create_staffing_assignment!(state, pm, q_hat_b)

        # Staffing satisfaction: s = (1-ω)*s + ω*(q - μ_b*q̂_b)  [§9c]
        expected = (1 - omega) * sat_before + omega * (q - params.mu_b * q_hat_b)
        @test firm.satisfaction_broker ≈ expected atol=1e-10
    end

    @testset "broker history records correct values" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        wid = get_avail_pool_worker(state)
        hc_before = state.broker.history_count
        pm = ProposedMatch(1, wid, :staffing, 1.5, 1.5, state.workers[wid].reservation_wage)
        q = create_staffing_assignment!(state, pm, 1.5)

        idx = mod1(state.broker.history_count, size(state.broker.history_w, 2))
        @test state.broker.history_w[:, idx] == state.workers[wid].type
        @test state.broker.history_x[:, idx] == state.firms[1].type
        @test state.broker.history_q[idx] == q
        @test state.broker.history_firm_idx[idx] == 1
    end

    @testset "bill rate and revenue values" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        empty!(state.broker.active_assignments)
        wid = get_avail_pool_worker(state)
        r_i = state.workers[wid].reservation_wage
        q_hat_b = 2.0
        pm = ProposedMatch(1, wid, :staffing, 1.5, q_hat_b, r_i)
        create_staffing_assignment!(state, pm, q_hat_b)

        sa = state.broker.active_assignments[end]
        @test sa.bill_rate ≈ r_i + params.mu_b * q_hat_b atol=1e-10
        @test sa.predicted_q == q_hat_b
        @test sa.reservation_wage == r_i

        # Process one period and check revenue
        reset_accumulators!(state.accum)
        process_staffing_economics!(state)
        c_emp = params.c_emp_frac * state.cal.r_base
        expected_rev = params.mu_b * q_hat_b - c_emp
        @test state.accum.staffing_revenue ≈ expected_rev atol=1e-10
    end

    @testset "single output draw: no RNG in process_staffing_economics!" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        wid = get_avail_pool_worker(state)
        pm = ProposedMatch(1, wid, :staffing, 1.5, 1.5, state.workers[wid].reservation_wage)
        q = create_staffing_assignment!(state, pm, 1.5)

        sa = state.broker.active_assignments[end]
        @test sa.realized_q == q
        process_staffing_economics!(state)
        @test sa.realized_q == q
    end

    @testset "expiration after L periods" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true, L=3)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        wid = get_avail_pool_worker(state)
        firm_idx = 1
        empty!(state.broker.active_assignments)
        pm = ProposedMatch(firm_idx, wid, :staffing, 1.5, 1.5, state.workers[wid].reservation_wage)
        create_staffing_assignment!(state, pm, 1.5)

        @test state.workers[wid].status == staffed
        for p in 1:2
            process_staffing_economics!(state)
            @test state.workers[wid].status == staffed
        end
        process_staffing_economics!(state)  # period 3→0, expires
        @test state.workers[wid].status == available
        @test state.workers[wid].broker_id == 0
        @test firm_idx ∈ state.open_vacancies
        @test isempty(state.broker.active_assignments)
    end

    @testset "vacancy guard: no duplicate on expiration" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true, L=2)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        wid = get_avail_pool_worker(state)
        firm_idx = 1
        push!(state.open_vacancies, firm_idx)
        empty!(state.broker.active_assignments)
        pm = ProposedMatch(firm_idx, wid, :staffing, 1.5, 1.5, state.workers[wid].reservation_wage)
        create_staffing_assignment!(state, pm, 1.5)

        process_staffing_economics!(state)
        process_staffing_economics!(state)  # expires
        @test firm_idx ∈ state.open_vacancies
        @test state.workers[wid].status == available
    end

    @testset "firm exit terminates assignments" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        # Clear any pre-existing assignments at firm_idx so we test exactly one
        firm_idx = 1
        filter!(a -> a.firm_idx != firm_idx, state.broker.active_assignments)

        wid = get_avail_pool_worker(state)
        pm = ProposedMatch(firm_idx, wid, :staffing, 1.5, 1.5, state.workers[wid].reservation_wage)
        create_staffing_assignment!(state, pm, 1.5)

        @test state.workers[wid].status == staffed
        n_before = length(state.broker.active_assignments)

        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        exit_firm!(state, firm_idx, avail)

        @test state.workers[wid].status == available
        @test state.workers[wid].broker_id == 0
        @test state.workers[wid].staffing_firm_id == 0
        @test length(state.broker.active_assignments) == n_before - 1
    end

    @testset "firm exit with multiple assignments at same firm" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        firm_idx = 1
        wids = Int[]
        empty!(state.broker.active_assignments)
        for _ in 1:3
            wid = get_avail_pool_worker(state)
            pm = ProposedMatch(firm_idx, wid, :staffing, 1.5, 1.5, state.workers[wid].reservation_wage)
            create_staffing_assignment!(state, pm, 1.5)
            push!(wids, wid)
        end
        @test length(state.broker.active_assignments) == 3

        avail = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end
        exit_firm!(state, firm_idx, avail)

        @test isempty(state.broker.active_assignments)
        for wid in wids
            @test state.workers[wid].status == available
        end
    end

    @testset "multiple concurrent assignments with staggered expiration" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true, L=4)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        empty!(state.broker.active_assignments)

        # Create 3 assignments at different firms, stagger by calling process between
        wid1 = get_avail_pool_worker(state)
        create_staffing_assignment!(state, ProposedMatch(1, wid1, :staffing, 1.5, 1.5,
            state.workers[wid1].reservation_wage), 1.5)

        process_staffing_economics!(state)  # wid1: 4→3

        wid2 = get_avail_pool_worker(state)
        create_staffing_assignment!(state, ProposedMatch(2, wid2, :staffing, 1.5, 1.5,
            state.workers[wid2].reservation_wage), 1.5)

        process_staffing_economics!(state)  # wid1: 3→2, wid2: 4→3

        wid3 = get_avail_pool_worker(state)
        create_staffing_assignment!(state, ProposedMatch(3, wid3, :staffing, 1.5, 1.5,
            state.workers[wid3].reservation_wage), 1.5)

        @test length(state.broker.active_assignments) == 3

        # Run until wid1 expires (2 more periods)
        process_staffing_economics!(state)  # wid1: 2→1, wid2: 3→2, wid3: 4→3
        @test length(state.broker.active_assignments) == 3
        process_staffing_economics!(state)  # wid1: 1→0 (expires), wid2: 2→1, wid3: 3→2
        @test length(state.broker.active_assignments) == 2
        @test state.workers[wid1].status == available
        @test state.workers[wid2].status == staffed
        @test state.workers[wid3].status == staffed

        # Run until wid2 expires
        process_staffing_economics!(state)  # wid2: 1→0 (expires), wid3: 2→1
        @test length(state.broker.active_assignments) == 1
        @test state.workers[wid2].status == available

        # Run until wid3 expires
        process_staffing_economics!(state)  # wid3: 1→0 (expires)
        @test isempty(state.broker.active_assignments)
        @test state.workers[wid3].status == available
    end

    @testset "conflict resolution: staffing loses to internal" begin
        rng = StableRNG(99)
        r_i = 0.7
        proposals = [
            ProposedMatch(1, 42, :staffing, 1.5, 1.5, r_i),
            ProposedMatch(2, 42, :internal, 1.2, 0.0, r_i + 0.25),
        ]
        accepted = resolve_conflicts(proposals, rng)
        @test length(accepted) == 1
        @test accepted[1].source == :internal
        @test accepted[1].firm_idx == 2
    end

    @testset "staffing integrates through step_period!" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true, T=100, T_burn=5)
        state = initialize_model(params)

        # Run enough periods for staffing to kick in
        for _ in 1:100; step_period!(state); end

        # Verify staffing occurred through the full step pipeline
        @test state.broker.history_count > 20  # broker learned from placements and staffing

        # Invariants should hold
        verify_invariants(state)

        # Check that metrics were recorded
        _, mdf = run_simulation(params)
        total_staffing = sum(mdf.n_staffing_new)
        total_placed = sum(mdf.n_placed)
        @test total_staffing + total_placed > 0
        # flow_capture_rate should have non-NaN values
        valid_fcr = filter(!isnan, mdf.flow_capture_rate)
        @test !isempty(valid_fcr)
    end

    @testset "broker_clients includes staffing firms for reputation" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true, T=80, T_burn=5)
        state = initialize_model(params)
        for _ in 1:80; step_period!(state); end

        # If there are active assignments, their firms should be in broker_clients
        if !isempty(state.broker.active_assignments)
            staffing_firm_idxs = Set(a.firm_idx for a in state.broker.active_assignments)
            # broker_clients is populated during step_period!, check it includes staffing firms
            @test staffing_firm_idxs ⊆ state.broker_clients
        end
    end

    # ── Toggle ──

    @testset "enable_staffing=false preserves base model" begin
        _, mdf_off = run_simulation(default_params(enable_staffing=false))
        @test all(mdf_off.n_staffing_new .== 0)
        @test all(mdf_off.n_active_staffing .== 0)
        @test all(isnan.(mdf_off.flow_capture_rate) .| (mdf_off.flow_capture_rate .== 0.0))
    end

    # ── Surplus accounting ──

    @testset "staffing surplus sums to total" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        wid = get_avail_pool_worker(state)
        r_i = state.workers[wid].reservation_wage
        q_hat_b = 1.5

        empty!(state.broker.active_assignments)
        reset_accumulators!(state.accum)

        pm = ProposedMatch(1, wid, :staffing, 1.5, q_hat_b, r_i)
        q = create_staffing_assignment!(state, pm, q_hat_b)

        # Surplus is accumulated by process_staffing_economics!, not create_
        @test state.accum.total_realized_surplus == 0.0
        process_staffing_economics!(state)

        a = state.accum
        @test a.worker_surplus == 0.0
        total_parts = a.worker_surplus + a.firm_surplus_staffed + a.broker_surplus_staffing
        @test total_parts ≈ a.total_realized_surplus atol=1e-10
        @test a.firm_surplus_staffed ≈ q - r_i - params.mu_b * q_hat_b atol=1e-10
        @test a.broker_surplus_staffing ≈ params.mu_b * q_hat_b atol=1e-10
    end

    @testset "staffing surplus lifecycle over L periods" begin
        params = default_params(d=4, N_W=200, N_F=10, enable_staffing=true, L=3)
        state = initialize_model(params)
        for _ in 1:20; step_period!(state); end

        wid = get_avail_pool_worker(state)
        r_i = state.workers[wid].reservation_wage
        q_hat_b = 1.5

        empty!(state.broker.active_assignments)
        pm = ProposedMatch(1, wid, :staffing, 1.5, q_hat_b, r_i)
        q = create_staffing_assignment!(state, pm, q_hat_b)

        cum_total = 0.0
        cum_broker = 0.0
        cum_firm = 0.0
        for _ in 1:params.L
            reset_accumulators!(state.accum)
            process_staffing_economics!(state)
            cum_total += state.accum.total_realized_surplus
            cum_broker += state.accum.broker_surplus_staffing
            cum_firm += state.accum.firm_surplus_staffed
        end

        @test cum_total ≈ params.L * (q - r_i) atol=1e-10
        @test cum_broker ≈ params.L * params.mu_b * q_hat_b atol=1e-10
        @test cum_firm ≈ params.L * (q - r_i - params.mu_b * q_hat_b) atol=1e-10
        @test isempty(state.broker.active_assignments)
        @test state.workers[wid].status == available
    end

end
