using Test
using TransientBrokerage

# Regression baseline: verify that a fixed-seed simulation produces known-good
# output values. Catches accidental changes to simulation dynamics or RNG stream.
# Baseline refreshed on 2026-04-16 after the approved round-based concurrent
# matching redesign, the approved shared-cost search simplification, and the
# approved cov_full regime-operator construction. Refreshed on 2026-04-17 after
# the approved self-search outside-option simplification that removes the
# separate score_known hurdle, layered on top of the hybrid broker-access
# specification. Refreshed on 2026-04-17 after setting the approved default
# satisfaction recency weight to omega = 0.2.
@testset "Regression Baseline" begin
    using Statistics: mean

    p = default_params(N=50, T=20, T_burn=5, seed=42)
    _, df = run_simulation(p)
    tail = df[df.period .> 5, :]

    # Match counts
    @test mean(tail.n_total_matches) ≈ 103.26666666666667 atol=0.01

    # Outsourcing rate
    @test mean(tail.outsourcing_rate) ≈ 0.1911266982157704 atol=1e-4

    # Prediction quality (per-agent averaged, hc>0 only)
    broker_r2 = mean(filter(!isnan, tail.broker_holdout_r2))
    agent_r2 = mean(filter(!isnan, tail.agent_holdout_r2))
    @test broker_r2 ≈ 0.09747864482162213 atol=1e-4
    @test agent_r2 ≈ 0.053482387300119005 atol=1e-4

    # Match output
    @test mean(filter(!isnan, tail.q_self_mean)) ≈ 1.5139370394191423 atol=1e-4

    # Broker state at end
    @test df.betweenness[end] ≈ 0.015994368241419712 atol=1e-6
    @test df.roster_size[end] == 10
end
