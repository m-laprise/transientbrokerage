using Test
using TransientBrokerage
using StableRNGs: StableRNG
using Graphs: nv, ne, degree, global_clustering_coefficient, connected_components, has_edge

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

    @testset "add_all_coworker_ties! creates complete subgraph" begin
        G = build_social_network(100, 6, 0.1, StableRNG(42))
        ids = Set([1, 2, 3, 4, 5])
        add_all_coworker_ties!(G, ids)
        # All 10 pairwise edges should exist
        count = sum(has_edge(G, i, j) for i in ids for j in ids if i < j)
        @test count == 10  # C(5,2) = 10
    end

    @testset "add_coworker_ties! adds edges to new hire" begin
        G = build_social_network(100, 6, 0.1, StableRNG(42))
        rng = StableRNG(99)
        # Create a firm with employees 1-20, then hire worker 50
        firm_emps = Set(1:20)
        push!(firm_emps, 50)
        edges_before = ne(G)
        add_coworker_ties!(G, 50, firm_emps, rng)
        edges_after = ne(G)
        # Should have added min(ceil(20/2), 10) = 10 new edges (some may be duplicates)
        @test edges_after > edges_before
        # Worker 50 should have at least one tie to a coworker
        @test any(has_edge(G, 50, wid) for wid in 1:20)
    end

    @testset "initialization creates coworker ties" begin
        state = initialize_model(default_params())
        # Initial employees (6-10 per firm) should be pairwise connected
        firm = state.firms[1]
        emps = collect(firm.employees)
        if length(emps) >= 2
            # All pairs should be connected
            n_pairs = length(emps) * (length(emps) - 1) ÷ 2
            n_connected = sum(has_edge(state.G_S, emps[i], emps[j])
                              for i in 1:length(emps) for j in (i+1):length(emps))
            @test n_connected == n_pairs
        end
    end
end
