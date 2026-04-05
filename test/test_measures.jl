using Test
using TransientBrokerage
using Graphs: SimpleGraph, add_edge!, star_graph, nv, ne

@testset "Network Measures" begin

    # Combined graph has correct node count and edge structure
    @testset "build_combined_graph structure" begin
        params = default_params(d=4, N_W=200, N_F=5)
        state = initialize_model(params)
        G, broker_node = build_combined_graph(state)

        @test nv(G) == params.N_W + length(state.firms) + 1
        @test broker_node == nv(G)

        # At init, no periods run → broker_clients is empty
        n_gs_edges = ne(state.G_S)
        n_emp_edges = sum(length(f.employees) for f in state.firms)
        n_pool_edges = length(state.broker.pool)
        @test ne(G) == n_gs_edges + n_emp_edges + n_pool_edges

        # After a step, G_S has grown (coworker ties) and broker-firm edges appear
        step_period!(state)
        G2, _ = build_combined_graph(state)
        n_gs_edges2 = ne(state.G_S)  # G_S grows from coworker ties during matching
        n_emp_edges2 = sum(length(f.employees) for f in state.firms)
        n_pool_edges2 = length(state.broker.pool)
        n_staffed_edges = length(state.broker.active_assignments)
        staffing_firm_idxs = Set(sa.firm_idx for sa in state.broker.active_assignments)
        n_broker_firm_total = length(union(
            Set(j for (j, f) in enumerate(state.firms) if f.last_channel == :broker),
            staffing_firm_idxs))
        @test ne(G2) == n_gs_edges2 + n_emp_edges2 + n_pool_edges2 + n_staffed_edges + n_broker_firm_total
        @test n_gs_edges2 >= n_gs_edges  # G_S only grows (coworker ties are permanent)
        @test n_broker_firm_total > 0
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

    # Cross-mode betweenness: star graph where broker connects disjoint workers and firms
    # Workers: {1,2}, Firms: {3,4}, Broker: 5
    # All 4 worker-firm paths pass through broker → crossmode = 1.0
    @testset "crossmode betweenness: pure broker star" begin
        G = SimpleGraph(5)
        add_edge!(G, 5, 1); add_edge!(G, 5, 2)
        add_edge!(G, 5, 3); add_edge!(G, 5, 4)
        @test compute_crossmode_betweenness(G, 5, 2, 2) ≈ 1.0
        # Worker node is never an intermediary (it's always a source/target)
        @test compute_crossmode_betweenness(G, 1, 2, 2) ≈ 0.0
        @test compute_crossmode_betweenness(G, 3, 2, 2) ≈ 0.0
    end

    # Cross-mode betweenness with a bypass edge: worker 1 connected directly to firm 3
    # Workers: {1,2}, Firms: {3,4}, Broker: 5
    # Edges: 5-1, 5-2, 5-3, 5-4, 1-3
    # Paths: 1→3 direct (no broker), 1→4 via 5, 2→3 via 5, 2→4 via 5
    # Broker crossmode = 3/4 = 0.75
    @testset "crossmode betweenness: star with bypass" begin
        G = SimpleGraph(5)
        add_edge!(G, 5, 1); add_edge!(G, 5, 2)
        add_edge!(G, 5, 3); add_edge!(G, 5, 4)
        add_edge!(G, 1, 3)  # bypass
        @test compute_crossmode_betweenness(G, 5, 2, 2) ≈ 0.75
    end

    # Cross-mode betweenness on a chain: 1 - 4 - 2 - 3
    # Workers: {1,2}, Firm: {3}, Broker: 4; N_W=2, N_F=1
    # 1→3: goes 1→4→2→3 (through 4)
    # 2→3: goes 2→3 directly (not through 4)
    # Broker crossmode = 1/2 = 0.5
    @testset "crossmode betweenness: chain" begin
        G = SimpleGraph(4)
        add_edge!(G, 1, 4); add_edge!(G, 4, 2); add_edge!(G, 2, 3)
        @test compute_crossmode_betweenness(G, 4, 2, 1) ≈ 0.5
    end

    # Cross-mode betweenness: broker has no cross-mode paths through it
    # Workers: {1,2}, Firm: {3}, Broker: 4
    # Workers directly connected to firm, broker disconnected
    @testset "crossmode betweenness: disconnected broker" begin
        G = SimpleGraph(4)
        add_edge!(G, 1, 3); add_edge!(G, 2, 3)
        @test compute_crossmode_betweenness(G, 4, 2, 1) ≈ 0.0
    end

    # Cross-mode betweenness: multiple shortest paths (tie-breaking)
    # Workers: {1,2}, Firm: {3}, Broker: 4, Extra node: 5
    # Edges: 1-4, 1-5, 4-3, 5-3, 2-3
    # 1→3: two shortest paths of length 2: 1→4→3 and 1→5→3
    #       Node 4 gets credit = 1/2 (one of two paths)
    # 2→3: direct
    # Broker crossmode = (1/2) / 2 = 0.25
    @testset "crossmode betweenness: tied shortest paths" begin
        G = SimpleGraph(5)
        add_edge!(G, 1, 4); add_edge!(G, 1, 5)
        add_edge!(G, 4, 3); add_edge!(G, 5, 3)
        add_edge!(G, 2, 3)
        @test compute_crossmode_betweenness(G, 4, 2, 1) ≈ 0.25
    end

    # update_cached_network_measures! produces finite non-zero values
    @testset "update_cached_network_measures!" begin
        params = default_params(d=4, N_W=200, N_F=5)
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
