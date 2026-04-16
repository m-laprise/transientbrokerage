using Test
using TransientBrokerage
using StableRNGs: StableRNG

@testset "Resource Capture (Principal Mode)" begin

    @testset "counterparty_ask uses history mean" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42)
        state = initialize_model(p)
        agent = state.agents[1]
        # Set known history values
        agent.history_count = 3
        agent.history_q[1] = 2.0
        agent.history_q[2] = 4.0
        agent.history_q[3] = 3.0
        @test counterparty_ask(agent, state.cal.q_cal) ≈ 3.0
    end

    @testset "counterparty_ask falls back to q_cal with no history" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42)
        state = initialize_model(p)
        agent = state.agents[1]
        agent.history_count = 0
        @test counterparty_ask(agent, state.cal.q_cal) == state.cal.q_cal
    end

    @testset "broker_mode_decision uses slower support/confidence threshold" begin
        K = 5
        # q̂_b = 5.0, ask = 2.0, φ = 0.5, κ = 1.0, s = 0: spread = 3.0 > 1.5
        @test broker_mode_decision(5.0, 2.0, 0.5, 1.0, 0, K) == true
        # q̂_b = 3.2, ask = 2.0, φ = 0.5, κ = 1.0, s = 0: spread = 1.2 < 1.5
        @test broker_mode_decision(3.2, 2.0, 0.5, 1.0, 0, K) == false
        # Small support lowers the penalty only slightly when scaled by K.
        @test broker_mode_decision(3.2, 2.0, 0.5, 1.0, 1, K) == false
        # Larger support eventually lowers the hurdle enough to clear.
        @test broker_mode_decision(3.2, 2.0, 0.5, 1.0, 15, K) == true
        # Boundary remains strict >
        @test broker_mode_decision(3.0, 2.0, 0.5, 1.0, 15, K) == false
    end

    @testset "apply_mode_selection! requires live confidence and uses slower support scaling" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=true)
        state = initialize_model(p)
        state.agents[5].history_count = 1
        state.agents[5].history_q[1] = 0.5
        state.agents[6].history_count = 1
        state.agents[6].history_q[1] = 0.5
        state.broker.capture_confidence_mae = 1.0
        state.broker.counterparty_support[6] = 15

        eval_q = 0.5 + state.cal.phi + 0.75
        proposals = ProposedMatch[
            ProposedMatch(1, 5, :broker, eval_q, false, NaN),
            ProposedMatch(2, 6, :broker, eval_q, false, NaN),
            ProposedMatch(3, 7, :self, 2.0, false, NaN),
        ]

        apply_mode_selection!(proposals, state.agents, state.broker, p, state.cal)
        @test all(!pm.is_principal for pm in proposals)

        state.broker.capture_confidence_ready = true
        proposals = ProposedMatch[
            ProposedMatch(1, 5, :broker, eval_q, false, NaN),  # s=0 => blocked by κ penalty
            ProposedMatch(2, 6, :broker, eval_q, false, NaN),  # large s => penalty shrinks, principal
            ProposedMatch(3, 7, :self, 2.0, false, NaN),
        ]
        apply_mode_selection!(proposals, state.agents, state.broker, p, state.cal)

        @test proposals[1].is_principal == false
        @test proposals[2].is_principal == true
        @test proposals[3].is_principal == false
        @test isnan(proposals[1].ask_j)
        @test proposals[2].ask_j ≈ 0.5
        @test isnan(proposals[3].ask_j)
    end

    @testset "apply_mode_selection! is no-op when disabled" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=false)
        state = initialize_model(p)
        proposals = [ProposedMatch(1, 5, :broker, 5.0, false, NaN)]
        apply_mode_selection!(proposals, state.agents, state.broker, p, state.cal)
        @test proposals[1].is_principal == false
    end

    @testset "counterparty support counts distinct demanders once" begin
        state = initialize_model(default_params(N=20, seed=42, enable_principal=true))
        @test all(==(0), state.broker.counterparty_support)

        TransientBrokerage.update_counterparty_support!(state.broker, 1, 5)
        TransientBrokerage.update_counterparty_support!(state.broker, 1, 5)
        TransientBrokerage.update_counterparty_support!(state.broker, 2, 5)

        @test state.broker.counterparty_support[5] == 2
        @test state.broker.support_seen[1, 5]
        @test state.broker.support_seen[2, 5]
    end

    @testset "support updates on accepted standard and principal broker matches" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=true)
        state = initialize_model(p)

        add_match_edge!(state.G, 1, 2)
        state.agents[2].partner_sum[1] = 10.0
        state.agents[2].partner_count[1] = 1

        proposals = ProposedMatch[
            ProposedMatch(1, 2, :broker, 3.0, false, NaN),
            ProposedMatch(3, 4, :broker, 3.0, true, 0.5),
        ]
        accepted = sequential_match_formation!(proposals, state.agents, state.broker,
                                               state.env, state.G, state.params,
                                               state.cal, state.rng)

        @test length(accepted) == 2
        @test state.broker.counterparty_support[2] == 1
        @test state.broker.counterparty_support[4] == 1
        @test state.broker.support_seen[1, 2]
        @test state.broker.support_seen[3, 4]
    end

    @testset "capture confidence starts unavailable before live broker matches" begin
        state = initialize_model(default_params(N=30, seed=42, enable_principal=true))
        @test state.broker.capture_confidence_ready == false
        @test state.broker.capture_confidence_mae == 0.0
    end

    @testset "capture confidence initializes from first live broker period and holds with no data" begin
        state = initialize_model(default_params(N=20, seed=42, enable_principal=true))
        @test state.broker.capture_confidence_ready == false

        TransientBrokerage.update_capture_confidence_mae!(state.broker, 3.0, 2, 0.25)
        @test state.broker.capture_confidence_ready == true
        @test state.broker.capture_confidence_mae ≈ 1.5

        TransientBrokerage.update_capture_confidence_mae!(state.broker, 1.0, 1, 0.25)
        @test state.broker.capture_confidence_mae ≈ (0.75 * 1.5 + 0.25 * 1.0)

        prev = state.broker.capture_confidence_mae
        TransientBrokerage.update_capture_confidence_mae!(state.broker, 0.0, 0, 0.25)
        @test state.broker.capture_confidence_mae == prev
    end

    @testset "first period is standard-only and initializes confidence from live broker MAE" begin
        p = default_params(N=80, T=3, T_burn=0, seed=42, enable_principal=true)
        state = initialize_model(p)

        step_period!(state)
        metrics = collect_period_metrics(state)

        @test metrics.period == 1
        @test metrics.n_broker_principal == 0
        @test isnan(metrics.broker_confidence_mae)
        @test !isnan(metrics.broker_selected_mae)
        @test state.broker.capture_confidence_ready == true
        @test state.broker.capture_confidence_mae ≈ metrics.broker_selected_mae
    end

    @testset "capture_surplus" begin
        @test capture_surplus(3.0, 1.0) ≈ 2.0     # positive surplus
        @test capture_surplus(0.5, 1.0) ≈ -0.5    # realized capture risk (Δq < 0)
        @test capture_surplus(1.0, 1.0) ≈ 0.0     # zero surplus
    end

    @testset "Full simulation with principal mode" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, enable_principal=true)
        _, df = run_simulation(p)
        @test length(df.n_broker_principal) == p.T
        # Principal mode share is between 0 and 1
        @test all(0.0 .<= df.principal_mode_share .<= 1.0)
        @test df.n_broker_principal[1] == 0
        @test isnan(df.broker_confidence_mae[1])
        @test :broker_selected_mae in propertynames(df)
        @test :broker_confidence_mae in propertynames(df)
        sel_mae = filter(!isnan, df.broker_selected_mae)
        conf_mae = filter(!isnan, df.broker_confidence_mae)
        @test all(>=(0.0), sel_mae)
        @test all(>=(0.0), conf_mae)
    end

    @testset "Cumulative match counters increment as expected" begin
        # Base model, no turnover (eta=0) so no counter resets from entry/exit:
        # every accepted match should increment both parties' n_matches_any;
        # n_principal_acquired stays at zero.
        p = default_params(N=60, T=10, T_burn=2, seed=321, eta=0.0)
        state, df = run_simulation(p)

        total_counter = sum(ag.n_matches_any for ag in state.agents)
        # Each match increments two agents; total counter should equal 2 × matches.
        @test total_counter == 2 * sum(df.n_total_matches)
        @test all(ag -> ag.n_principal_acquired == 0, state.agents)

        # With principal mode on, n_principal_acquired increments on the counterparty side.
        p2 = default_params(N=60, T=10, T_burn=2, seed=321, eta=0.0, enable_principal=true)
        state2, df2 = run_simulation(p2)
        total_principal_acq = sum(ag.n_principal_acquired for ag in state2.agents)
        # Each principal match increments the counterparty's counter once.
        @test total_principal_acq == sum(df2.n_broker_principal)
    end

    @testset "Counters reset on agent exit/entry" begin
        # Verify that exit + entry zeroes the counters so a new occupant of the
        # slot starts fresh (otherwise D_j would inherit the prior agent's stats).
        p = default_params(N=40, T=5, T_burn=1, seed=202, eta=0.0, enable_principal=true)
        state = initialize_model(p)
        agent = state.agents[1]
        agent.n_matches_any = 7
        agent.n_principal_acquired = 3
        rng = state.rng
        exit_agent!(state, 1)
        enter_agent!(state, 1, rng)
        @test state.agents[1].n_matches_any == 0
        @test state.agents[1].n_principal_acquired == 0
    end

    @testset "Capture outcome metrics match hand computation" begin
        using Statistics: mean
        p = default_params(N=60, T=12, T_burn=2, seed=777, enable_principal=true)
        state, df = run_simulation(p)

        # Recompute mean capture surplus from the accumulator vectors on the final period.
        a = state.accum
        if !isempty(a.q_broker_principal)
            expected_delta = a.q_broker_principal .- a.q_bar_j_principal
            expected_mean = mean(expected_delta)
            @test df.capture_surplus_mean[end] ≈ expected_mean
            # Loss rate: fraction with Δq < 0
            expected_loss_rate = count(<(0.0), expected_delta) / length(expected_delta)
            @test df.capture_loss_rate[end] ≈ expected_loss_rate
        else
            @test isnan(df.capture_surplus_mean[end])
            @test isnan(df.capture_loss_rate[end])
        end

        # With no principal matches (enable_principal=false), capture metrics are NaN.
        p3 = default_params(N=60, T=10, T_burn=2, seed=111, enable_principal=false)
        _, df3 = run_simulation(p3)
        @test all(isnan, df3.capture_surplus_mean)
        @test all(isnan, df3.capture_loss_rate)
        @test all(isnan, df3.capture_decision_rank)
        @test all(isnan, df3.capture_decision_rmse)
    end

    @testset "Broker dependency columns are well-formed" begin
        p = default_params(N=60, T=12, T_burn=2, seed=444, enable_principal=true)
        _, df = run_simulation(p)
        # Dependency mean is in [0, 1] whenever defined.
        deps = filter(!isnan, df.broker_dependency_mean)
        @test all(0.0 .<= deps .<= 1.0)
        # Fraction-above-half lies in [0, 1].
        frac = filter(!isnan, df.broker_dependency_frac_above_half)
        @test all(0.0 .<= frac .<= 1.0)
        # Gini lies in [0, 1].
        g = filter(!isnan, df.broker_dependency_gini)
        @test all(0.0 .<= g .<= 1.0)
    end
end
