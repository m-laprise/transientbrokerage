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
    # Regenerated after refactoring entry/exit to share available set across entries
    expected = [
        (8,   4,  25, 106),  # period 1
        (13, 17,  30, 112),  # period 2
        (14, 17,  35, 116),  # period 3
        (15, 19,  40, 121),  # period 4
        (10, 22,  45, 127),  # period 5
        (7,  28,  50, 131),  # period 6
        (16, 43,  55, 137),  # period 7
        (6,  44,  60, 138),  # period 8
        (10, 45,  65, 143),  # period 9
        (10, 46,  70, 153),  # period 10
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
