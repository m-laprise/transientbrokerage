using Test
using TransientBrokerage
using Graphs: SimpleGraph, add_edge!, star_graph, nv, ne, watts_strogatz, betweenness_centrality

@testset "Network Measures" begin

    # Combined graph has correct node count and edge structure
    @testset "build_combined_graph structure" begin
        params = default_params(d=4, N_W=50, N_F=5)
        state = initialize_model(params)
        G, broker_node = build_combined_graph(state)

        @test nv(G) == params.N_W + length(state.firms) + 1
        @test broker_node == nv(G)

        # Count expected edges
        n_gs_edges = ne(state.G_S)
        n_emp_edges = sum(length(f.employees) for f in state.firms)
        n_pool_edges = length(state.broker.pool)
        @test ne(G) == n_gs_edges + n_emp_edges + n_pool_edges
    end

    # Star graph: center has betweenness = 1.0 (normalized)
    @testset "betweenness on star graph" begin
        G = star_graph(6)  # node 1 is center, nodes 2-6 are leaves
        @test compute_betweenness(G, 1) ≈ 1.0
        @test compute_betweenness(G, 2) ≈ 0.0
    end

    # Star graph: center has low constraint (contacts are disconnected)
    # For a star with k leaves: each p_ij = 1/k, no indirect paths,
    # so C = k * (1/k)^2 = 1/k
    @testset "Burt's constraint on star graph" begin
        G = star_graph(6)
        c = compute_burt_constraint(G, 1)
        @test c ≈ 1.0 / 5.0  # 5 leaves
    end

    # Star graph: center effective size = deg (all contacts non-redundant)
    @testset "effective size on star graph" begin
        G = star_graph(6)
        es = compute_effective_size(G, 1)
        @test es ≈ 5.0
    end

    # Isolated node: constraint = 1.0, effective_size = 0.0
    @testset "isolated node" begin
        G = SimpleGraph(3)
        add_edge!(G, 1, 2)
        @test compute_burt_constraint(G, 3) == 1.0
        @test compute_effective_size(G, 3) == 0.0
    end

    # Complete triangle: node 1 has 2 neighbors (2,3) who are connected
    # p_1j = 1/2, deg(2) = deg(3) = 2, so p_qj = 1/2
    # j=2: indirect = p_13 * p_32 = 1/2 * 1/2 = 1/4; contribution: (1/2 + 1/4)^2 = 9/16
    # j=3: indirect = p_12 * p_23 = 1/2 * 1/2 = 1/4; contribution: (1/2 + 1/4)^2 = 9/16
    # Total = 18/16 = 1.125
    @testset "Burt's constraint on complete triangle" begin
        G = SimpleGraph(3)
        add_edge!(G, 1, 2)
        add_edge!(G, 1, 3)
        add_edge!(G, 2, 3)
        c = compute_burt_constraint(G, 1)
        @test c ≈ 1.125
    end

    # Complete triangle: effective size
    # deg = 2, redundancy = sum_j p_1j * sum_{q!=1} p_1q * m_jq
    # j=2: p_12 * p_13 * m(2,3) = 1/2 * 1/2 * 1 = 1/4
    # j=3: p_13 * p_12 * m(3,2) = 1/2 * 1/2 * 1 = 1/4
    # ES = 2 - 1/2 = 1.5
    @testset "effective size on complete triangle" begin
        G = SimpleGraph(3)
        add_edge!(G, 1, 2)
        add_edge!(G, 1, 3)
        add_edge!(G, 2, 3)
        es = compute_effective_size(G, 1)
        @test es ≈ 1.5
    end

    # Hand-built 5-node graph: node 1 bridges two disconnected pairs
    # 1--2, 1--3, 1--4, 1--5, 2--3, 4--5
    # Node 1 has deg=4, p_1j = 1/4. All neighbors have deg=2, so p_qj = 1/2.
    # j=2: indirect = p_13 * p_32 = 1/4 * 1/2 = 1/8; contribution: (1/4+1/8)^2 = 9/64
    # j=3: same = 9/64; j=4: same = 9/64; j=5: same = 9/64
    # Total C = 36/64 = 0.5625
    @testset "hand-built bridge graph: constraint" begin
        G = SimpleGraph(5)
        add_edge!(G, 1, 2); add_edge!(G, 1, 3)
        add_edge!(G, 1, 4); add_edge!(G, 1, 5)
        add_edge!(G, 2, 3); add_edge!(G, 4, 5)
        c = compute_burt_constraint(G, 1)
        @test c ≈ 0.5625
    end

    # Same graph: effective size for node 1
    # deg=4, redundancy:
    #   (j=2,q=3): p*p*m(2,3) = 1/16 * 1 = 1/16
    #   (j=2,q=4): 1/16 * 0 = 0
    #   (j=2,q=5): 1/16 * 0 = 0
    #   (j=3,q=2): 1/16 * 1 = 1/16
    #   (j=3,q=4): 0; (j=3,q=5): 0
    #   (j=4,q=2): 0; (j=4,q=3): 0
    #   (j=4,q=5): 1/16 * 1 = 1/16
    #   (j=5,q=2): 0; (j=5,q=3): 0
    #   (j=5,q=4): 1/16 * 1 = 1/16
    # Total redundancy = 4/16 = 1/4
    # ES = 4 - 0.25 = 3.75
    @testset "hand-built bridge graph: effective size" begin
        G = SimpleGraph(5)
        add_edge!(G, 1, 2); add_edge!(G, 1, 3)
        add_edge!(G, 1, 4); add_edge!(G, 1, 5)
        add_edge!(G, 2, 3); add_edge!(G, 4, 5)
        es = compute_effective_size(G, 1)
        @test es ≈ 3.75
    end

    # Parallel Brandes matches Graphs.jl reference on non-trivial graphs
    @testset "betweenness matches Graphs.jl reference" begin
        # Hand-built bridge graph (same as above)
        G1 = SimpleGraph(5)
        add_edge!(G1, 1, 2); add_edge!(G1, 1, 3)
        add_edge!(G1, 1, 4); add_edge!(G1, 1, 5)
        add_edge!(G1, 2, 3); add_edge!(G1, 4, 5)
        ref1 = betweenness_centrality(G1)
        for v in 1:nv(G1)
            @test compute_betweenness(G1, v) ≈ ref1[v] atol=1e-12
        end

        # Watts-Strogatz small-world (realistic topology)
        G2 = watts_strogatz(100, 6, 0.1; seed=42)
        ref2 = betweenness_centrality(G2)
        for v in [1, 25, 50, 75, 100]
            @test compute_betweenness(G2, v) ≈ ref2[v] atol=1e-12
        end

        # Combined graph from actual model state
        params = default_params(d=4, N_W=50, N_F=5)
        state = initialize_model(params)
        G3, broker_node = build_combined_graph(state)
        ref3 = betweenness_centrality(G3)
        @test compute_betweenness(G3, broker_node) ≈ ref3[broker_node] atol=1e-12
        # Also spot-check a few worker and firm nodes
        for v in [1, 10, 30, params.N_W + 1, params.N_W + 3]
            @test compute_betweenness(G3, v) ≈ ref3[v] atol=1e-12
        end
    end

    # update_cached_network_measures! produces finite non-zero values
    @testset "update_cached_network_measures!" begin
        params = default_params(d=4, N_W=50, N_F=5)
        state = initialize_model(params)
        # Run a few periods to build some history
        for _ in 1:5
            step_period!(state)
        end
        update_cached_network_measures!(state)
        @test isfinite(state.cached_network.betweenness)
        @test isfinite(state.cached_network.constraint)
        @test isfinite(state.cached_network.effective_size)
        @test state.cached_network.betweenness > 0.0
        @test state.cached_network.effective_size > 0.0
    end
end
