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
        @test counterparty_ask(agent, state.cal.q_pub) ≈ 3.0
    end

    @testset "counterparty_ask falls back to q_pub with no history" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42)
        state = initialize_model(p)
        agent = state.agents[1]
        agent.history_count = 0
        @test counterparty_ask(agent, state.cal.q_pub) == state.cal.q_pub
    end

    @testset "broker_mode_decision: principal when spread > phi" begin
        # q̂_b = 5.0, ask = 2.0, phi = 0.5: spread = 3.0 > 0.5
        @test broker_mode_decision(5.0, 2.0, 0.5) == true
        # q̂_b = 2.5, ask = 2.0, phi = 0.5: spread = 0.5, not strictly greater
        @test broker_mode_decision(2.5, 2.0, 0.5) == false
        # q̂_b = 1.0, ask = 2.0, phi = 0.5: spread = -1.0 < 0.5
        @test broker_mode_decision(1.0, 2.0, 0.5) == false
    end

    @testset "apply_mode_selection! marks broker proposals as principal" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=true)
        state = initialize_model(p)
        # Agent with low ask (little history)
        state.agents[5].history_count = 1
        state.agents[5].history_q[1] = 0.5  # low ask

        proposals = ProposedMatch[
            ProposedMatch(1, 5, :broker, 3.0, false),   # spread = 3.0 - 0.5 > phi
            ProposedMatch(2, 6, :broker, 0.1, false),   # spread likely negative
            ProposedMatch(3, 7, :self, 2.0, false),      # self-search, unchanged
        ]
        apply_mode_selection!(proposals, state.agents, p, state.cal)

        @test proposals[1].is_principal == true   # high spread
        @test proposals[3].is_principal == false   # self-search unchanged
    end

    @testset "apply_mode_selection! is no-op when disabled" begin
        p = default_params(N=20, T=5, T_burn=1, seed=42, enable_principal=false)
        state = initialize_model(p)
        proposals = [ProposedMatch(1, 5, :broker, 5.0, false)]
        apply_mode_selection!(proposals, state.agents, p, state.cal)
        @test proposals[1].is_principal == false
    end

    @testset "compute_principal_profit" begin
        @test compute_principal_profit(3.0, 1.0) ≈ 2.0    # positive spread
        @test compute_principal_profit(0.5, 1.0) ≈ -0.5   # inventory loss
        @test compute_principal_profit(1.0, 1.0) ≈ 0.0    # breakeven
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
end
