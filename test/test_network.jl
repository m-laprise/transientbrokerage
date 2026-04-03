using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Graphs: nv, ne, degree, global_clustering_coefficient, connected_components

@testset "Network" begin
    N_W = 1000
    k_S = 6

    @testset "build_social_network returns correct graph" begin
        G = build_social_network(N_W, k_S, 0.1, StableRNG(42))
        @test nv(G) == N_W
        avg_deg = 2 * ne(G) / nv(G)
        @test abs(avg_deg - k_S) < 1.0
    end

    @testset "graph is connected or nearly so" begin
        G = build_social_network(N_W, k_S, 0.1, StableRNG(42))
        comps = connected_components(G)
        @test length(comps) <= 2
        @test maximum(length.(comps)) >= 0.99 * N_W
    end

    @testset "small-world clustering" begin
        G = build_social_network(N_W, k_S, 0.1, StableRNG(42))
        @test global_clustering_coefficient(G) > 0.0
    end

    @testset "referral pools" begin
        state = initialize_model(default_params())
        # Firms with employees have non-empty referral pools
        @test all(!isempty(f.referral_pool) for f in state.firms if !isempty(f.employees))
        # No employee appears in their own firm's referral pool
        @test all(isempty(intersect(f.employees, f.referral_pool)) for f in state.firms)
    end
end
