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
    # Regenerated after calibration with actual firm types and entrant firms on curve
    expected = [
        (26, 12, 200, 105),  # period 1
        (21, 14, 200, 110),  # period 2
        (11, 16, 200, 117),  # period 3
        (18, 17, 200, 120),  # period 4
        (13, 18, 200, 126),  # period 5
        (10, 18, 200, 128),  # period 6
        (14, 18, 200, 135),  # period 7
        (14, 19, 200, 142),  # period 8
        (9,  20, 200, 148),  # period 9
        (18, 29, 200, 152),  # period 10
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
