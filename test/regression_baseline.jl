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
    # N_F=50, p_vac=0.50, 6-10 initial workers, broker seeded with 10
    # Holdout evaluation in step.jl consumes RNG for random worker draws
    expected = [
        (22, 19, 200, 54),  # period 1
        (29, 25, 200, 56),  # period 2
        (20, 36, 200, 57),  # period 3
        (27, 48, 200, 58),  # period 4
        (25, 70, 200, 62),  # period 5
        (20, 84, 200, 63),  # period 6
        (21, 94, 200, 64),  # period 7
        (19, 109, 200, 68),  # period 8
        (26, 123, 200, 70),  # period 9
        (25, 137, 200, 73),  # period 10
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
