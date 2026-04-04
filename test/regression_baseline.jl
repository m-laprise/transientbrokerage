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
    expected = [
        (37, 36, 79, 54),  # period 1
        (30, 60, 76, 54),  # period 2
        (31, 84, 74, 56),  # period 3
        (43, 118, 60, 57),  # period 4
        (33, 139, 74, 61),  # period 5
        (37, 166, 72, 65),  # period 6
        (33, 182, 76, 69),  # period 7
        (35, 200, 80, 71),  # period 8
        (37, 224, 75, 76),  # period 9
        (32, 242, 75, 80),  # period 10
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
