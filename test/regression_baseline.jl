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
    # N_F=50, p_vac=0.50, sigma_w=0.2, 6-10 initial workers, broker seeded with 10
    # Features: firm=[w; w.^2], broker=[w; x; w.*x; w.^2]
    expected = [
        (26, 23, 200, 52),  # period 1
        (28, 31, 200, 57),  # period 2
        (25, 40, 200, 61),  # period 3
        (29, 54, 200, 62),  # period 4
        (30, 67, 200, 66),  # period 5
        (30, 81, 200, 67),  # period 6
        (21, 91, 200, 71),  # period 7
        (27, 103, 200, 74),  # period 8
        (20, 113, 200, 76),  # period 9
        (23, 123, 200, 80),  # period 10
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
