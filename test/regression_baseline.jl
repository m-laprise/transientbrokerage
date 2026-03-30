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
    # N_F=50, p_vac=0.50, sigma_w=0.5, 6-10 initial workers, broker seeded with 20
    # Features: firm=[w; w.^2], broker=[w; x; w.*x; w.^2]
    expected = [
        (28, 36, 200, 52),  # period 1
        (31, 57, 200, 57),  # period 2
        (38, 84, 200, 60),  # period 3
        (28, 100, 200, 64),  # period 4
        (26, 112, 200, 65),  # period 5
        (23, 130, 200, 65),  # period 6
        (29, 149, 200, 68),  # period 7
        (22, 164, 200, 69),  # period 8
        (17, 176, 200, 73),  # period 9
        (23, 191, 200, 75),  # period 10
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
