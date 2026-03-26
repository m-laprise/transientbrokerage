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
    # Regenerated after fixed-target pool mechanics (pool_target_frac=0.20, placed workers leave)
    expected = [
        (8,   4, 200, 105),  # period 1
        (14,  4, 200, 112),  # period 2
        (6,   4, 200, 116),  # period 3
        (18,  5, 200, 119),  # period 4
        (7,  12, 200, 122),  # period 5
        (10, 22, 200, 131),  # period 6
        (10, 31, 200, 139),  # period 7
        (10, 34, 200, 146),  # period 8
        (6,  34, 200, 150),  # period 9
        (9,  34, 200, 156),  # period 10
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
