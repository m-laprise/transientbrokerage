using Test

@testset "TransientBrokerage" begin
    include("test_types.jl")
    include("test_matching_function.jl")
    include("test_network.jl")
    include("test_initialization.jl")
    include("test_learning.jl")
    include("test_search.jl")
    include("test_matching.jl")
    include("test_step.jl")
    include("regression_baseline.jl")
end
