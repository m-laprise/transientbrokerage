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
    # Pool replenishment: 50/50 referral (G_S neighbors of pool) / random
    # Features: firm=[w; w.^2], broker=[w; x; w⊗x; w.^2]
    expected = [
        (22, 32, 100, 54),  # period 1
        (34, 62, 100, 55),  # period 2
        (20, 75, 100, 59),  # period 3
        (23, 92, 100, 60),  # period 4
        (22, 108, 100, 61),  # period 5
        (26, 123, 100, 65),  # period 6
        (24, 143, 100, 67),  # period 7
        (25, 163, 100, 68),  # period 8
        (22, 181, 100, 69),  # period 9
        (23, 201, 100, 73),  # period 10
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
