# Regression baseline: verify that a fixed-seed simulation produces known-good
# output values. Catches accidental changes to simulation dynamics or RNG stream.
# If this test fails after an intentional model change, regenerate the baseline
# by running the simulation at (N=50, T=20, T_burn=5, seed=42) and updating
# the expected values below.
@testset "Regression Baseline" begin
    using Statistics: mean

    p = default_params(N=50, T=20, T_burn=5, seed=42)
    _, df = run_simulation(p)
    tail = df[df.period .> 5, :]

    # Match counts
    @test mean(tail.n_total_matches) ≈ 78.133 atol=0.01

    # Outsourcing rate
    @test mean(tail.outsourcing_rate) ≈ 0.53558 atol=1e-4

    # Prediction quality (holdout)
    broker_r2 = mean(filter(!isnan, tail.broker_holdout_r2))
    agent_r2 = mean(filter(!isnan, tail.agent_holdout_r2))
    @test broker_r2 ≈ 0.45744 atol=1e-4
    @test agent_r2 ≈ 0.23893 atol=1e-4

    # Match output
    @test mean(filter(!isnan, tail.q_self_mean)) ≈ 1.68748 atol=1e-4

    # Broker state at end
    @test df.betweenness[end] ≈ 0.27691 atol=1e-4
    @test df.broker_cumulative_revenue[end] ≈ 69.705 atol=1e-2
    @test df.roster_size[end] == 48
end
