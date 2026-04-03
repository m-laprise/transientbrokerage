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
    # Pool maintenance at start of period; no-proposal penalty pulls toward zero
    # Features: firm=[w; w.^2], broker=[w; x; w⊗x; w.^2]
    expected = [
        (29, 28, 90, 55),  # period 1
        (22, 34, 92, 57),  # period 2
        (32, 53, 79, 60),  # period 3
        (21, 63, 81, 64),  # period 4
        (24, 74, 85, 66),  # period 5
        (29, 90, 77, 73),  # period 6
        (26, 107, 81, 75),  # period 7
        (19, 121, 82, 76),  # period 8
        (19, 135, 83, 78),  # period 9
        (29, 154, 80, 81),  # period 10
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
