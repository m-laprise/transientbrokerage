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

    # Frozen values: (matches, broker_history_count, broker_pool_size)
    # Generated with --check-bounds=yes (Pkg.test default)
    # Regenerated after fixing order-dependence in outsourcing reputation (prev_broker_firms)
    expected = [
        (8,  4,  25),  # period 1
        (12, 16, 30),  # period 2
        (9,  16, 35),  # period 3
        (12, 19, 40),  # period 4
        (5,  19, 45),  # period 5
        (13, 21, 50),  # period 6
        (10, 23, 55),  # period 7
        (10, 26, 60),  # period 8
        (8,  32, 65),  # period 9
        (10, 37, 70),  # period 10
    ]

    for (t, (exp_matches, exp_hist, exp_pool)) in enumerate(expected)
        step_period!(state)
        @test state.period == t
        @test state.accum.matches == exp_matches
        @test state.broker.history_count == exp_hist
        @test length(state.broker.pool) == exp_pool
    end
end
