using Test
using TransientBrokerage
using Graphs: SimpleGraph
using StableRNGs: StableRNG

@testset "Phase 0: Types and Parameters" begin
    # Keyword overrides replace defaults without affecting other fields
    @testset "default_params with overrides" begin
        p = default_params(; seed = 99, d = 10)
        @test p.seed == 99
        @test p.d == 10
    end

    # Typos or invalid parameter names raise immediately
    @testset "default_params rejects unknown kwargs" begin
        @test_throws ErrorException default_params(; bogus_param = 42)
    end

    # Per-period fields zero out; cumulative revenue survives the reset
    @testset "reset_accumulators!" begin
        accum = PeriodAccumulators()
        # Set some per-period fields
        accum.matches = 10
        accum.new_staffing = 5
        accum.new_placements = 3
        push!(accum.q_direct, 1.0, 2.0)
        push!(accum.q_placed, 3.0)
        push!(accum.q_staffed, 4.0)
        accum.openings_internal = 7
        accum.openings_brokered = 8
        accum.placement_revenue = 100.0
        accum.staffing_revenue = 200.0
        # Set cumulative fields
        accum.cumulative_placement_revenue = 500.0
        accum.cumulative_staffing_revenue = 1000.0

        reset_accumulators!(accum)

        # Per-period fields are zeroed/emptied
        @test accum.matches == 0
        @test accum.new_staffing == 0
        @test accum.new_placements == 0
        @test isempty(accum.q_direct)
        @test isempty(accum.q_placed)
        @test isempty(accum.q_staffed)
        @test accum.openings_internal == 0
        @test accum.openings_brokered == 0
        @test accum.placement_revenue == 0.0
        @test accum.staffing_revenue == 0.0
        # Cumulative fields are preserved
        @test accum.cumulative_placement_revenue == 500.0
        @test accum.cumulative_staffing_revenue == 1000.0
    end
end
