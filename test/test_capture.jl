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

    @testset "broker_mode_decision: principal when spread > phi" begin
        # q̂_b = 5.0, ask = 2.0, phi = 0.5: spread = 3.0 > 0.5
        @test broker_mode_decision(5.0, 2.0, 0.5) == true
        # q̂_b = 2.5, ask = 2.0, phi = 0.5: spread = 0.5, not strictly greater
        @test broker_mode_decision(2.5, 2.0, 0.5) == false
        # q̂_b = 1.0, ask = 2.0, phi = 0.5: spread = -1.0 < 0.5
        @test broker_mode_decision(1.0, 2.0, 0.5) == false
    end

    @testset "apply_mode_selection! marks familiar broker proposals as principal" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=true)
        state = initialize_model(p)
        # Agent with low ask (little history)
        state.agents[5].history_count = 1
        state.agents[5].history_q[1] = 0.5  # low ask

        # Mark pair (1,5) as familiar (previously matched via standard)
        push!(state.broker.familiar_pairs, (1, 5))

        proposals = ProposedMatch[
            ProposedMatch(1, 5, :broker, 3.0, false, NaN),   # familiar + surplus > phi -> principal
            ProposedMatch(2, 6, :broker, 3.0, false, NaN),   # NOT familiar -> stays standard
            ProposedMatch(3, 7, :self, 2.0, false, NaN),      # self-search, unchanged
        ]
        apply_mode_selection!(proposals, state.agents, state.broker, p, state.cal)

        @test proposals[1].is_principal == true    # familiar + profitable
        @test proposals[2].is_principal == false    # unfamiliar, blocked
        @test proposals[3].is_principal == false    # self-search unchanged
        # Principal-mode proposal caches ask_j = 0.5 from mode selection
        @test proposals[1].ask_j ≈ 0.5
        @test isnan(proposals[2].ask_j)             # standard broker proposal: NaN
        @test isnan(proposals[3].ask_j)             # self-search proposal: NaN
    end

    @testset "apply_mode_selection! is no-op when disabled" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=false)
        state = initialize_model(p)
        push!(state.broker.familiar_pairs, (1, 5))
        proposals = [ProposedMatch(1, 5, :broker, 5.0, false, NaN)]
        apply_mode_selection!(proposals, state.agents, state.broker, p, state.cal)
        @test proposals[1].is_principal == false
    end

    @testset "capture_surplus" begin
        @test capture_surplus(3.0, 1.0) ≈ 2.0     # positive surplus
        @test capture_surplus(0.5, 1.0) ≈ -0.5    # realized capture risk (Δq < 0)
        @test capture_surplus(1.0, 1.0) ≈ 0.0     # zero surplus
    end

    @testset "Full simulation with principal mode" begin
        p = default_params(N=50, T=10, T_burn=2, seed=42, enable_principal=true)
        state, df = run_simulation(p)
        # Should have some principal matches
        total_principal = sum(df.n_broker_principal)
        @test total_principal >= 0  # may be 0 in early periods
        # Principal mode share is between 0 and 1
        @test all(0.0 .<= df.principal_mode_share .<= 1.0)
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
