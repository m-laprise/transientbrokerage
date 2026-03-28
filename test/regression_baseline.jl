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
    # Features: firm=[w; w.^2], broker=[w; x; w.*x; w.^2]
    expected = [
        (23, 19, 200, 54),  # period 1
        (30, 27, 200, 56),  # period 2
        (23, 40, 200, 58),  # period 3
        (28, 57, 200, 61),  # period 4
        (23, 71, 200, 63),  # period 5
        (22, 84, 200, 63),  # period 6
        (22, 102, 200, 66),  # period 7
        (28, 123, 200, 69),  # period 8
        (26, 141, 200, 70),  # period 9
        (23, 157, 200, 71),  # period 10
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
