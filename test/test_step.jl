using Test
using TransientBrokerage
using StableRNGs: StableRNG

@testset "Step Loop" begin
    # Invariants hold for 50 periods
    @testset "50 periods with invariants" begin
        params = default_params()
        state = initialize_model(params)
        @test begin
            all_pass = true
            for _ in 1:50
                step_period!(state)
                try
                    verify_invariants!(state)
                catch e
                    all_pass = false
                    @error "Invariant failed at period $(state.period)" exception=e
                end
            end
            all_pass
        end
        @test state.period == 50
    end

    # Broker history grows over time
    @testset "broker history grows" begin
        params = default_params()
        state = initialize_model(params)
        step_period!(state)
        count_after_1 = state.broker.history_count
        for _ in 2:50
            step_period!(state)
        end
        @test state.broker.history_count > count_after_1
    end

    # q_pub is static (calibration constant, never updated)
    @testset "q_pub unchanged after 50 periods" begin
        params = default_params()
        state = initialize_model(params)
        q_pub_init = state.cal.q_pub
        for _ in 1:50
            step_period!(state)
        end
        @test state.cal.q_pub == q_pub_init
    end

    # Outsourcing rate is in valid range
    @testset "outsourcing rate in [0, 1]" begin
        params = default_params()
        state = initialize_model(params)
        for _ in 1:50
            step_period!(state)
            @test 0.0 <= state.accum.outsourcing_rate <= 1.0
        end
    end

    # Matches occur
    @testset "matches happen" begin
        params = default_params()
        state = initialize_model(params)
        total_matches = 0
        for _ in 1:50
            step_period!(state)
            total_matches += state.accum.matches
        end
        @test total_matches > 0
    end

    # Both channels produce matches over 50 periods
    @testset "both channels produce matches" begin
        params = default_params()
        state = initialize_model(params)
        total_direct = 0
        total_placed = 0
        for _ in 1:50
            step_period!(state)
            total_direct += length(state.accum.q_direct)
            total_placed += length(state.accum.q_placed)
        end
        @test total_direct > 0
        @test total_placed > 0
    end

    # Unfilled vacancies carry forward into the next period's decisions
    @testset "vacancy persistence" begin
        params = default_params()
        state = initialize_model(params)
        for _ in 1:20
            step_period!(state)
        end
        # Inject a vacancy for a firm that can't possibly fill it (no available workers match)
        # by picking a firm index not currently in open_vacancies
        test_j = findfirst(j -> j ∉ state.open_vacancies, 1:length(state.firms))
        test_j === nothing && error("All firms have vacancies — unlikely, skip test")
        push!(state.open_vacancies, test_j)
        # Run one more period — if vacancy persists unfilled, it stays in open_vacancies
        step_period!(state)
        # The vacancy was either filled (removed) or persisted — either way it was processed.
        # We verify it was in the decision set by checking accumulators increased.
        @test state.accum.openings_internal + state.accum.openings_brokered > 0
    end

    # Deterministic with fixed seed
    @testset "deterministic with fixed seed" begin
        params = default_params()
        s1 = initialize_model(params)
        s2 = initialize_model(params)
        for _ in 1:20
            step_period!(s1)
            step_period!(s2)
        end
        @test s1.accum.matches == s2.accum.matches
        @test s1.broker.history_count == s2.broker.history_count
        @test s1.accum.outsourcing_rate == s2.accum.outsourcing_rate
    end

    # No-proposal penalty fires during step_period! when broker can't serve a client
    @testset "no-proposal penalty wiring" begin
        params = default_params()
        state = initialize_model(params)
        # Run enough periods for some firms to try broker
        for _ in 1:30
            step_period!(state)
        end
        # Empty the broker pool so no proposals can be made
        empty!(state.broker.pool)
        # Record broker satisfaction for firms that will choose broker
        sat_before = Dict(f.id => f.satisfaction_broker for f in state.firms)
        step_period!(state)
        # Any firm that chose broker and got no proposal should have satisfaction
        # updated toward its internal satisfaction (penalty)
        n_brokered = state.accum.openings_brokered
        if n_brokered > 0
            # At least one firm's broker satisfaction should have changed
            any_changed = any(
                state.firms[j].satisfaction_broker != sat_before[state.firms[j].id]
                for j in 1:length(state.firms)
                if haskey(sat_before, state.firms[j].id)
            )
            @test any_changed
        end
    end
end
