using Test
using TransientBrokerage
using Graphs: nv, ne, neighbors, has_edge, degree, SimpleGraph, add_edge!
using StableRNGs: StableRNG
using LinearAlgebra: normalize

@testset "Network" begin
    N = 20

    @testset "build_network creates N+1 nodes" begin
        G = build_network(N, 6, 0.1, StableRNG(42))
        @test nv(G) == N + 1
        @test degree(G, N + 1) == 0  # broker initially isolated
        @test all(degree(G, i) >= 1 for i in 1:N)
    end

    @testset "add_match_edge! is idempotent" begin
        G = build_network(N, 6, 0.1, StableRNG(42))
        edges_before = ne(G)
        add_match_edge!(G, 1, 2)
        add_match_edge!(G, 1, 2)
        @test ne(G) - edges_before <= 1
        @test has_edge(G, 1, 2)
    end

    @testset "add_broker_edge!" begin
        G = build_network(N, 6, 0.1, StableRNG(42))
        add_broker_edge!(G, 5, N + 1)
        @test has_edge(G, 5, N + 1)
    end

    @testset "remove_agent_edges!" begin
        G = build_network(N, 6, 0.1, StableRNG(42))
        @test degree(G, 1) > 0
        remove_agent_edges!(G, 1)
        @test degree(G, 1) == 0
    end

    @testset "add_entrant_edges! by type proximity" begin
        rng = StableRNG(42)
        G = build_network(N, 6, 0.1, rng)
        types = [normalize(randn(rng, 8)) for _ in 1:N]
        # Build minimal Agent structs for the new add_entrant_edges! signature
        d = 8; h_a = 16
        mock_agents = [Agent(id=i, type=types[i],
            history_X=Matrix{Float64}(undef, d, 0), history_q=Float64[],
            nn=init_neural_net(d, h_a, rng), nn_grad=NNGradBuffers(init_neural_net(d, h_a, rng)),
            predict_buf=zeros(h_a), partner_sum=zeros(N), partner_count=zeros(Int, N),
        ) for i in 1:N]
        remove_agent_edges!(G, 1)
        add_entrant_edges!(G, 1, types[1], mock_agents, rng; n_edges=3)
        @test degree(G, 1) == 3
        @test !has_edge(G, 1, 1)  # no self-edge
    end

    @testset "Network measures" begin
        G = build_network(5, 4, 0.0, StableRNG(42))
        for i in 1:5
            add_broker_edge!(G, i, 6)
        end
        bc = compute_betweenness(G, 6)
        @test isfinite(bc)
        @test 0.0 <= bc <= 1.0  # betweenness must be in [0, 1]
        @test isfinite(compute_burt_constraint(G, 6))
        @test isfinite(compute_effective_size(G, 6))
    end

    @testset "Betweenness correctness on path graph" begin
        # Path: 1 - 2 - 3 - 4 - 5
        # Node 3 is on shortest paths for 4 pairs: (1,4), (1,5), (2,4), (2,5)
        # Normalization: C(n-1, 2) = C(4,2) = 6 pairs excluding node 3
        # BC(3) = 4/6 = 0.667
        G = SimpleGraph(5)
        add_edge!(G, 1, 2)
        add_edge!(G, 2, 3)
        add_edge!(G, 3, 4)
        add_edge!(G, 4, 5)
        bc3 = compute_betweenness(G, 3)
        @test bc3 ≈ 4.0 / 6.0 atol=0.01
        @test 0.0 <= bc3 <= 1.0
    end

    @testset "Betweenness of star center" begin
        # Star: node 1 connected to 2,3,4,5.
        # All C(4,2)=6 pairs of leaves have shortest paths through node 1.
        # Normalization: C(n-1, 2) = C(4,2) = 6
        # BC(1) = 6/6 = 1.0
        G = SimpleGraph(5)
        for i in 2:5
            add_edge!(G, 1, i)
        end
        bc1 = compute_betweenness(G, 1)
        @test bc1 ≈ 1.0 atol=0.01
        @test 0.0 <= bc1 <= 1.0
    end

    @testset "Betweenness is zero for leaf node" begin
        # Path: 1 - 2 - 3. Node 1 is a leaf, no shortest paths go through it.
        G = SimpleGraph(3)
        add_edge!(G, 1, 2)
        add_edge!(G, 2, 3)
        @test compute_betweenness(G, 1) ≈ 0.0 atol=0.001
    end

    @testset "Isolated node measures" begin
        G = build_network(5, 4, 0.0, StableRNG(42))
        @test compute_burt_constraint(G, 6) == 1.0
        @test compute_effective_size(G, 6) == 0.0
    end
end
