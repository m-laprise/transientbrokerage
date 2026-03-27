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
    # d=4, ridge regression, firm+broker history seeded at init
    expected = [
        (31, 27, 200, 107),  # period 1
        (23, 29, 200, 110),  # period 2
        (35, 30, 200, 118),  # period 3
        (27, 38, 200, 122),  # period 4
        (16, 40, 200, 124),  # period 5
        (15, 42, 200, 126),  # period 6
        (9,  43, 200, 132),  # period 7
        (24, 45, 200, 137),  # period 8
        (19, 46, 200, 144),  # period 9
        (12, 48, 200, 150),  # period 10
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
