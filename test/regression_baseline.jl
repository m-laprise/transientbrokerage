# Frozen regression baseline: exact values from 10 periods at default_params(seed=42).
# Any code change that alters RNG consumption order will break this test.
# When making a deliberate change, update the frozen values and document why.
#
# Values generated under --check-bounds=yes (Pkg.test default). Running without
# bounds checking produces different RNG sequences because @inbounds elision
# changes code paths. Always regenerate with: julia --project --check-bounds=yes
using Test
using TransientBrokerage

@testset "Regression Baseline" begin
    params = default_params()
    state = initialize_model(params)

    # Frozen values: (matches, broker_history_count, broker_pool_size, next_firm_id)
    # Generated with --check-bounds=yes (Pkg.test default)
    # N_F=50, p_vac=0.50, sigma_w=0.5, pool_target_frac=0.10, broker seeded with 20
    # n_candidates_frac=0.03, pool maintenance at start, no-proposal penalty toward zero
    # Features: firm=[w; w.^2], broker=[w; x; w⊗x; w.^2]
    # Vacancy: 50/50 chance of 1 or 2 vacancies per draw
    # Pool: direct sampling from eligible workers (no rejection sampling)
    # Coworker ties: half of coworkers (max 5) on hire; pairwise at init/entry
    expected = [
        (37, 36, 79, 53),  # period 1
        (34, 64, 71, 55),  # period 2
        (40, 93, 68, 58),  # period 3
        (26, 112, 76, 61),  # period 4
        (31, 128, 83, 63),  # period 5
        (34, 149, 74, 66),  # period 6
        (33, 174, 70, 68),  # period 7
        (30, 193, 79, 72),  # period 8
        (30, 203, 84, 75),  # period 9
        (44, 228, 80, 78),  # period 10
    ]

    for (t, (exp_matches, exp_hist, exp_pool, exp_next_id)) in enumerate(expected)
        step_period!(state)
        @test state.period == t
        @test state.accum.matches == exp_matches
        @test state.broker.history_count == exp_hist
        @test length(state.broker.pool) == exp_pool
        @test state.next_firm_id == exp_next_id
    end
end
