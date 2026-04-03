using Test
using TransientBrokerage
using StableRNGs: StableRNG

@testset "Entry/Exit" begin
    params = default_params(d=4, N_W=200, N_F=20)
    N_W = params.N_W

    # Helper: build available set from state
    make_avail(state) = let bv = falses(length(state.workers)); for w in state.workers; w.status == available && (bv[w.id] = true); end; bv end

    # exit_firm! releases employees and clears vacancy
    @testset "exit_firm! releases employees" begin
        state = initialize_model(params)
        firm_idx = 1
        emp_ids = collect(state.firms[firm_idx].employees)
        @test !isempty(emp_ids)

        push!(state.open_vacancies, firm_idx)
        avail = make_avail(state)
        exit_firm!(state, firm_idx, avail)

        @test isempty(state.firms[firm_idx].employees)
        @test all(state.workers[wid].status == available for wid in emp_ids)
        @test all(state.workers[wid].employer_id == 0 for wid in emp_ids)
        @test firm_idx ∉ state.open_vacancies
        # Released employees added to available set
        @test all(avail[wid] for wid in emp_ids)
    end

    # enter_firm! creates a fresh firm with employees
    @testset "enter_firm! creates fresh entrant" begin
        state = initialize_model(params)
        avail = make_avail(state)
        exit_firm!(state, 1, avail)
        old_next_id = state.next_firm_id
        candidates = Vector{Int}(undef, N_W)
        wts = Vector{Float64}(undef, N_W)

        enter_firm!(state, 1, avail, candidates, wts)
        new_firm = state.firms[1]

        @test new_firm.id == old_next_id
        @test state.next_firm_id == old_next_id + 1
        @test 6 <= length(new_firm.employees) <= 10
        @test 6 <= new_firm.history_count <= 10  # seeded from initial hires
        @test new_firm.satisfaction_internal == state.cal.q_pub
        @test new_firm.satisfaction_broker == state.cal.q_pub
        @test new_firm.tried_internal == false
        @test new_firm.tried_broker == false
        @test all(-3.0 .<= new_firm.type .<= 3.0)
    end

    # Entrant's employees are correctly linked and removed from available
    @testset "enter_firm! employees have correct status" begin
        state = initialize_model(params)
        avail = make_avail(state)
        exit_firm!(state, 1, avail)
        candidates = Vector{Int}(undef, N_W)
        wts = Vector{Float64}(undef, N_W)
        enter_firm!(state, 1, avail, candidates, wts)
        new_firm = state.firms[1]
        for wid in new_firm.employees
            @test state.workers[wid].status == employed
            @test state.workers[wid].employer_id == new_firm.id
            @test !avail[wid]
        end
    end

    # Worker conservation after exit+enter cycle
    @testset "worker conservation" begin
        state = initialize_model(params)
        n_before = count(w -> w.status == available, state.workers) +
                   count(w -> w.status == employed, state.workers)
        avail = make_avail(state)
        candidates = Vector{Int}(undef, N_W)
        wts = Vector{Float64}(undef, N_W)
        exit_firm!(state, 1, avail)
        enter_firm!(state, 1, avail, candidates, wts)
        n_after = count(w -> w.status == available, state.workers) +
                  count(w -> w.status == employed, state.workers)
        @test n_after == n_before
        @test n_after == N_W
    end

    # Workers released by exit stay in broker pool if they were there
    @testset "exit preserves broker pool membership" begin
        state = initialize_model(params)
        emp_id = first(state.firms[1].employees)
        push!(state.broker.pool, emp_id)

        avail = make_avail(state)
        exit_firm!(state, 1, avail)
        @test emp_id in state.broker.pool
    end

    # process_entry_exit! runs without error and maintains invariants
    # (pool maintenance runs after entry/exit in step_period!, so clean pool here)
    @testset "process_entry_exit! maintains invariants" begin
        state = initialize_model(params)
        for _ in 1:10
            step_period!(state)
        end
        avail = make_avail(state)
        process_entry_exit!(state, avail)
        # Clean pool (normally done in step 6 of step_period!)
        for wid in collect(state.broker.pool)
            state.workers[wid].status == available || delete!(state.broker.pool, wid)
        end
        verify_invariants(state)
    end

    # Turnover rate approximately equals eta over many periods
    @testset "turnover rate approximates eta" begin
        state = initialize_model(params)
        n_periods = 500
        exit_count = 0
        for _ in 1:n_periods
            ids_before = Set(f.id for f in state.firms)
            avail = make_avail(state)
            process_entry_exit!(state, avail)
            ids_after = Set(f.id for f in state.firms)
            exit_count += length(setdiff(ids_before, ids_after))
        end
        observed_rate = exit_count / (n_periods * params.N_F)
        expected = params.eta
        se = sqrt(expected * (1 - expected) / (n_periods * params.N_F))
        @test abs(observed_rate - expected) < 2 * se
    end
end
