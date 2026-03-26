using Test
using TransientBrokerage
using StableRNGs: StableRNG

@testset "Matching" begin

    # Wage = r_i + beta_W * max(q_hat - r_i, 0)
    @testset "compute_wage formula" begin
        @test compute_wage(10.0, 3.0, 0.5) == 3.0 + 0.5 * 7.0  # 6.5
        @test compute_wage(2.0, 3.0, 0.5) == 3.0  # no surplus
        @test compute_wage(3.0, 3.0, 0.5) == 3.0  # zero surplus
        @test compute_wage(10.0, 3.0, 1.0) == 10.0  # full surplus to worker
        @test compute_wage(10.0, 3.0, 0.0) == 3.0  # no surplus share
    end

    # Worker accepts highest-wage offer
    @testset "conflict resolution: highest wage wins" begin
        p1 = ProposedMatch(1, 42, :internal, 8.0, 0.0, 5.5)
        p2 = ProposedMatch(2, 42, :broker, 10.0, 10.0, 7.0)
        accepted = resolve_conflicts([p1, p2], StableRNG(1))
        @test length(accepted) == 1
        @test accepted[1].firm_idx == 2
        @test accepted[1].wage == 7.0
    end

    # Equal wages: resolved randomly (both outcomes possible)
    @testset "conflict resolution: ties broken randomly" begin
        p1 = ProposedMatch(1, 42, :internal, 8.0, 0.0, 5.0)
        p2 = ProposedMatch(2, 42, :broker, 8.0, 8.0, 5.0)
        outcomes = Set{Int}()
        for seed in 1:100
            accepted = resolve_conflicts([p1, p2], StableRNG(seed))
            push!(outcomes, accepted[1].firm_idx)
        end
        @test length(outcomes) == 2
    end

    # No conflicts: all proposals accepted
    @testset "conflict resolution: no conflicts" begin
        p1 = ProposedMatch(1, 10, :internal, 8.0, 0.0, 5.0)
        p2 = ProposedMatch(2, 20, :broker, 9.0, 9.0, 6.0)
        accepted = resolve_conflicts([p1, p2], StableRNG(1))
        @test length(accepted) == 2
    end

    # Empty proposals
    @testset "conflict resolution: empty" begin
        accepted = resolve_conflicts(ProposedMatch[], StableRNG(1))
        @test isempty(accepted)
    end

    # After finalize_match!, worker is employed, firm has the employee
    @testset "finalize_match! updates state" begin
        params = default_params(d=4, s=1, N_W=100, N_F=10)
        state = initialize_model(params)
        # Find an available worker
        avail_w = findfirst(w -> w.status == available, state.workers)
        worker = state.workers[avail_w]
        firm_idx = 1
        firm = state.firms[firm_idx]
        old_emp_count = length(firm.employees)
        old_hist_count = firm.history_count

        match = ProposedMatch(firm_idx, avail_w, :internal, 5.0, 0.0,
                              compute_wage(5.0, worker.reservation_wage, params.beta_W))
        z_buf = zeros(params.s)
        Ax_buf = zeros(params.d)
        q = finalize_match!(match, state, z_buf, Ax_buf)

        @test isfinite(q)
        @test worker.status == employed
        @test worker.employer_id == firm.id
        @test avail_w in firm.employees
        @test length(firm.employees) == old_emp_count + 1
        @test firm.history_count == old_hist_count + 1
        @test firm.hire_count == 1
    end

    # Brokered match records to broker history; placed worker NOT added to pool
    @testset "finalize_match! broker match updates broker" begin
        params = default_params(d=4, s=1, N_W=100, N_F=10)
        state = initialize_model(params)
        # Pick an available worker that is in the pool
        pool_w = first(w for w in state.workers if w.status == available && w.id in state.broker.pool)
        old_broker_count = state.broker.history_count

        match = ProposedMatch(1, pool_w.id, :broker, 5.0, 6.0,
                              compute_wage(5.0, pool_w.reservation_wage, params.beta_W))
        z_buf = zeros(params.s)
        Ax_buf = zeros(params.d)
        finalize_match!(match, state, z_buf, Ax_buf)

        @test state.broker.history_count == old_broker_count + 1
        # Worker is now employed; pool removal happens during step 4.4 maintenance
        @test state.workers[pool_w.id].status == employed
    end

    # Circular buffer wraps correctly, effective_history_size stays capped
    @testset "record_history! circular buffer" begin
        rng = StableRNG(1)
        firm = create_firm(1, 4, rng)
        cap = size(firm.history_w, 2)  # 200
        # Fill to capacity
        for i in 1:cap
            record_history!(firm, randn(rng, 4), Float64(i))
        end
        @test firm.history_count == cap
        @test effective_history_size(firm) == cap
        @test firm.history_q[cap] == Float64(cap)
        # Write one more — wraps to position 1
        record_history!(firm, ones(4), 999.0)
        @test firm.history_count == cap + 1
        @test effective_history_size(firm) == cap  # capped
        @test firm.history_q[1] == 999.0  # overwrote position 1
        @test firm.history_w[:, 1] == ones(4)
    end

    # Prediction still works after buffer overflow (integration test for the fix)
    @testset "prediction after history overflow" begin
        rng = StableRNG(1)
        firm = create_firm(1, 4, rng)
        cap = size(firm.history_w, 2)
        for i in 1:(cap + 50)
            record_history!(firm, clamp.(randn(rng, 4), -3.0, 3.0), randn(rng))
        end
        n = effective_history_size(firm)
        tree = KDTree(@view firm.history_w[:, 1:n])
        cache = PredictionCache(10)
        result = predict_firm(firm, randn(rng, 4), 0.0, 10, tree, cache)
        @test isfinite(result.q_hat)
        @test isfinite(result.mean_dist)
    end

    # Broker circular buffer
    @testset "record_broker_history! circular buffer" begin
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        broker = state.broker
        cap = size(broker.history_w, 2)
        rng = StableRNG(1)
        for i in 1:cap
            record_broker_history!(broker, randn(rng, 4), randn(rng, 4), 1, Float64(i))
        end
        @test broker.history_count == cap
        record_broker_history!(broker, ones(4), ones(4) * 2, 3, 888.0)
        @test broker.history_count == cap + 1
        @test broker.history_q[1] == 888.0
        @test broker.history_firm_idx[1] == 3
    end

    # EWMA satisfaction update
    @testset "update_satisfaction! EWMA formula" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_internal = 5.0
        firm.satisfaction_broker = 5.0
        omega = 0.3
        # Internal: s = 0.7*5 + 0.3*(10 - 2) = 3.5 + 2.4 = 5.9
        update_satisfaction!(firm, :internal, 10.0, omega; cost_above_ri=2.0)
        @test firm.satisfaction_internal ≈ 5.9
        @test firm.tried_internal == true
        # Broker: s = 0.7*5 + 0.3*(8 - 1) = 3.5 + 2.1 = 5.6
        update_satisfaction!(firm, :broker, 8.0, omega; cost_above_ri=1.0)
        @test firm.satisfaction_broker ≈ 5.6
        @test firm.tried_broker == true
    end

    # No-proposal penalty moves broker satisfaction toward internal
    @testset "penalize_no_proposal!" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_internal = 8.0
        firm.satisfaction_broker = 4.0
        penalize_no_proposal!(firm, 0.3)
        @test firm.satisfaction_broker ≈ 0.7 * 4.0 + 0.3 * 8.0
    end

    # Access vs assessment classification
    @testset "record_match! access vs assessment" begin
        accum = PeriodAccumulators()
        # Brokered match, worker NOT in referral pool → access
        record_match!(accum, :broker, false)
        @test accum.access_count == 1
        @test accum.assessment_count == 0
        @test accum.matches == 1
        # Brokered match, worker IN referral pool → assessment
        record_match!(accum, :broker, true)
        @test accum.assessment_count == 1
        @test accum.access_count == 1
        @test accum.matches == 2
        # Internal match → neither access nor assessment
        record_match!(accum, :internal, false)
        @test accum.access_count == 1
        @test accum.assessment_count == 1
        @test accum.matches == 3
    end

    # Wage uses firm's prediction, not broker's
    @testset "wage uses firm prediction for brokered match" begin
        q_hat_firm = 10.0
        q_hat_broker = 15.0
        r_i = 3.0
        beta_W = 0.5
        wage = compute_wage(q_hat_firm, r_i, beta_W)
        @test wage == r_i + beta_W * (q_hat_firm - r_i)
        @test wage != r_i + beta_W * (q_hat_broker - r_i)
    end
end

@testset "Outsourcing Decision" begin
    # Equal satisfaction: random tie-breaking produces both outcomes over many draws
    @testset "equal satisfaction -> random choice" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_internal = 5.0
        firm.satisfaction_broker = 5.0
        firm.tried_broker = true
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        broker = state.broker
        clients = Set{Int}()
        outcomes = [outsourcing_decision(firm, broker, 5.0, StableRNG(i))
                    for i in 1:100]
        @test :internal in outcomes
        @test :broker in outcomes
    end

    # Higher broker satisfaction leads to outsourcing
    @testset "higher broker satisfaction -> :broker" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_internal = 3.0
        firm.satisfaction_broker = 7.0
        firm.tried_broker = true
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        dec = outsourcing_decision(firm, state.broker, 5.0, StableRNG(1))
        @test dec == :broker
    end

    # Higher internal satisfaction leads to internal
    @testset "higher internal satisfaction -> :internal" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_internal = 7.0
        firm.satisfaction_broker = 3.0
        firm.tried_broker = true
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        dec = outsourcing_decision(firm, state.broker, 5.0, StableRNG(1))
        @test dec == :internal
    end

    # Untried broker uses cached reputation
    @testset "untried broker uses reputation" begin
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        firm = state.firms[1]
        firm.tried_broker = false
        firm.satisfaction_internal = 3.0
        # Cache a high reputation via update_broker_reputation!
        state.firms[2].satisfaction_broker = 10.0
        update_broker_reputation!(state.broker, state.firms, Set{Int}([2]))
        dec = outsourcing_decision(firm, state.broker, 5.0, StableRNG(1))
        @test dec == :broker
    end

    # update_broker_reputation! caches value; broker_reputation reads it back;
    # sticky: retains value when broker loses all clients
    @testset "broker reputation sticky with update" begin
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        broker = state.broker
        # Update with clients -> caches last_reputation
        state.firms[1].satisfaction_broker = 8.0
        update_broker_reputation!(broker, state.firms, Set{Int}([1]))
        @test broker.has_had_clients == true
        @test broker.last_reputation == 8.0
        @test broker_reputation(broker, 5.0) == 8.0
        # Change client satisfaction, re-update -> cache updates
        state.firms[1].satisfaction_broker = 6.0
        update_broker_reputation!(broker, state.firms, Set{Int}([1]))
        @test broker.last_reputation == 6.0
        # No clients this period -> cache unchanged (sticky)
        update_broker_reputation!(broker, state.firms, Set{Int}())
        @test broker_reputation(broker, 5.0) == 6.0
    end

    # Broker that has never had clients defaults to q_pub
    @testset "never-had-clients defaults to q_pub" begin
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        broker = state.broker
        broker.has_had_clients = false
        @test broker_reputation(broker, 3.14) == 3.14
    end

    # Negative satisfaction: no floor applied
    @testset "negative satisfaction allowed" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_broker = -5.0
        firm.tried_broker = true
        firm.satisfaction_internal = -3.0
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        # Internal is higher (-3 > -5), so should pick internal
        dec = outsourcing_decision(firm, state.broker, 5.0, StableRNG(1))
        @test dec == :internal
    end

    # Channel switching: decision flips when satisfaction trajectory crosses
    @testset "channel switching when trajectories cross" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.tried_broker = true
        firm.satisfaction_internal = 6.0
        firm.satisfaction_broker = 4.0
        params = default_params(d=4, s=1, N_W=100, N_F=5)
        state = initialize_model(params)
        # Initially internal wins
        dec1 = outsourcing_decision(firm, state.broker, 5.0, StableRNG(1))
        @test dec1 == :internal
        # After good broker experience, broker wins
        firm.satisfaction_broker = 8.0
        dec2 = outsourcing_decision(firm, state.broker, 5.0, StableRNG(1))
        @test dec2 == :broker
    end

    # Known analytic EWMA trajectory
    @testset "satisfaction matches analytic EWMA trajectory" begin
        firm = create_firm(1, 4, StableRNG(1))
        firm.satisfaction_internal = 5.0
        omega = 0.3
        # Period 1: q=10, cost=2 -> s = 0.7*5 + 0.3*8 = 5.9
        update_satisfaction!(firm, :internal, 10.0, omega; cost_above_ri=2.0)
        @test firm.satisfaction_internal ≈ 5.9
        # Period 2: q=4, cost=1 -> s = 0.7*5.9 + 0.3*3 = 4.13 + 0.9 = 5.03
        update_satisfaction!(firm, :internal, 4.0, omega; cost_above_ri=1.0)
        @test firm.satisfaction_internal ≈ 5.03
        # Period 3: q=7, cost=0 -> s = 0.7*5.03 + 0.3*7 = 3.521 + 2.1 = 5.621
        update_satisfaction!(firm, :internal, 7.0, omega; cost_above_ri=0.0)
        @test firm.satisfaction_internal ≈ 5.621
    end
end
