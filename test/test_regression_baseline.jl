using Test
using TransientBrokerage

# Regression baseline: verify that a fixed-seed simulation produces known-good
# output values. Catches accidental changes to simulation dynamics or RNG stream.
# Baseline refreshed on 2026-04-16 after the approved standard-R² correction,
# the approved ideal-type draw alignment with the written model specification,
# and the approved availability-metric fix.
@testset "Regression Baseline" begin
    using Statistics: mean

    p = default_params(N=50, T=20, T_burn=5, seed=42)
    _, df = run_simulation(p)
    tail = df[df.period .> 5, :]

    # Match counts
    @test mean(tail.n_total_matches) ≈ 78.53333333333333 atol=0.01

    # Outsourcing rate
    @test mean(tail.outsourcing_rate) ≈ 0.0056066176470588236 atol=1e-4

    # Prediction quality (per-agent averaged, hc>0 only)
    broker_r2 = mean(filter(!isnan, tail.broker_holdout_r2))
    agent_r2 = mean(filter(!isnan, tail.agent_holdout_r2))
    @test broker_r2 ≈ -0.08632525881091245 atol=1e-4
    @test agent_r2 ≈ -0.02338898053324796 atol=1e-4

    # Match output
    @test mean(filter(!isnan, tail.q_self_mean)) ≈ 1.6081172487946267 atol=1e-4

    # Broker state at end
    @test df.betweenness[end] ≈ 0.0 atol=1e-6
    @test df.roster_size[end] == 1
end
