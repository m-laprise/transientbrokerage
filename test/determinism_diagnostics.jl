# Per-layer determinism diagnostics.
# NOT included in runtests.jl — run manually when the integration-level
# determinism test fails, to localize which layer broke reproducibility.
#
# Usage: julia --project --threads=auto test/determinism_diagnostics.jl

using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Graphs: ne

@testset "Determinism Diagnostics" begin
    @testset "matching function" begin
        d = 4; rho = 0.5
        geo = generate_firm_geometry(:complex, d, 50, StableRNG(10))
        ftypes = generate_firm_types(geo, 50, d, StableRNG(10))
        env = generate_matching_function(d, rho, ftypes, StableRNG(42))
        w = randn(StableRNG(1), d)
        x = randn(StableRNG(1), d)
        q1 = match_output(w, x, env, StableRNG(10))
        q2 = match_output(w, x, env, StableRNG(10))
        @test q1 == q2
    end

    @testset "network" begin
        G1 = build_social_network(200, 6, 0.1, StableRNG(99))
        G2 = build_social_network(200, 6, 0.1, StableRNG(99))
        @test ne(G1) == ne(G2)
    end

    @testset "initialization" begin
        params = default_params()
        s1 = initialize_model(params)
        s2 = initialize_model(params)
        @test s1.cal.r_base == s2.cal.r_base
        @test s1.cal.f_bar == s2.cal.f_bar
        @test s1.workers[1].type == s2.workers[1].type
        @test s1.workers[1].reservation_wage == s2.workers[1].reservation_wage
        @test s1.firms[1].type == s2.firms[1].type
    end

    @testset "learning" begin
        d = 4; lambda = 1.0
        rng = StableRNG(42)
        firm = create_firm(1, d, rng)
        for _ in 1:20
            w = randn(rng, d)
            record_history!(firm, w, sum(w .* firm.type) + 0.1 * randn(rng))
        end
        n = effective_history_size(firm)
        model1 = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), lambda)
        model2 = fit_ridge(@view(firm.history_w[:, 1:n]), @view(firm.history_q[1:n]), lambda)
        w = randn(StableRNG(1), d)
        @test predict_ridge(model1, w) == predict_ridge(model2, w)
    end

    @testset "step_period!" begin
        params = default_params()
        s1 = initialize_model(params)
        s2 = initialize_model(params)
        for _ in 1:20
            step_period!(s1)
            step_period!(s2)
        end
        @test s1.accum.matches == s2.accum.matches
        @test s1.broker.history_count == s2.broker.history_count
        @test s1.accum.outsourcing_rate == s2.accum.outsourcing_rate
    end
end
