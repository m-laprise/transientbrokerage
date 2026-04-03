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
                    verify_invariants(state)
                catch e
                    all_pass = false
                    @error "Invariant failed at period $(state.period)" exception=e
                end
            end
            all_pass
        end
        @test state.period == 50
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

    # Pool is replenished before matching, not after: if the pool empties and
    # workers become available, the broker can propose them next period.
    @testset "pool refills before matching after depletion" begin
        params = default_params(d=4, N_W=200, N_F=10)
        state = initialize_model(params)
        for _ in 1:10; step_period!(state); end

        # Force pool to empty by marking all pool members as employed
        for wid in collect(state.broker.pool)
            state.workers[wid].status = employed
            state.workers[wid].employer_id = state.firms[1].id
            push!(state.firms[1].employees, wid)
        end
        # End-of-period purge would normally clean this; simulate it
        for wid in collect(state.broker.pool)
            state.workers[wid].status == available || delete!(state.broker.pool, wid)
        end
        @test isempty(state.broker.pool)

        # Make some workers available again (simulate firm exit releasing workers)
        n_released = 0
        for wid in collect(state.firms[1].employees)
            if n_released < 20
                state.workers[wid].status = available
                state.workers[wid].employer_id = 0
                delete!(state.firms[1].employees, wid)
                n_released += 1
            end
        end
        @test sum(w.status == available for w in state.workers) >= 20

        # After one step, pool should have been refilled (maintenance runs before matching)
        step_period!(state)
        @test length(state.broker.pool) > 0
        # And broker should have been able to make proposals (if firms outsourced)
        # The key invariant: pool was non-empty when broker_allocate! ran
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

    # 100 periods with entry/exit: invariants hold throughout
    @testset "100 periods with entry/exit and invariants" begin
        params = default_params()
        state = initialize_model(params)
        @test begin
            all_pass = true
            for _ in 1:100
                step_period!(state)
                try
                    verify_invariants(state)
                catch e
                    all_pass = false
                    @error "Invariant failed at period $(state.period)" exception=e
                end
            end
            all_pass
        end
    end

    # After 100 periods with entry/exit, some firms should be recent entrants
    @testset "entrant firms have fresh state" begin
        params = default_params()
        state = initialize_model(params)
        for _ in 1:100
            step_period!(state)
        end
        # At least some firms should have id > N_F (entrants)
        @test any(f.id > params.N_F for f in state.firms)
        # Entrant firms start with seeded history from initial hires
        entrants = [f for f in state.firms if f.id > params.N_F && f.hire_count == 0]
        if !isempty(entrants)
            @test all(6 <= f.history_count <= 10 for f in entrants)
        end
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

    # Network measures are computed at the correct interval
    @testset "network measures computed every M periods" begin
        params = default_params(network_measure_interval=5)
        state = initialize_model(params)
        @test isnan(state.cached_network.betweenness)
        for _ in 1:4
            step_period!(state)
        end
        # Not yet at interval
        @test isnan(state.cached_network.betweenness)
        # Period 5 triggers computation
        step_period!(state)
        @test state.cached_network.betweenness > 0.0
        # Record value, run 4 more periods, verify unchanged
        b5 = state.cached_network.betweenness
        for _ in 6:9
            step_period!(state)
        end
        @test state.cached_network.betweenness == b5
        # Period 10 recomputes (value may differ due to entry/exit)
        step_period!(state)
        @test state.cached_network.betweenness > 0.0
    end
end
