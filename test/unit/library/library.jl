include("solution.jl")
include("model.jl")


function test_library()
    @testset "Library" begin
        test_solution()
        test_model()
    end

    return nothing
end