include("error.jl")
include("tools.jl")
include("solution.jl")

function test_library()
    @testset "⦷ Library ⦷" verbose = true begin
        test_error()
        test_tools()
        test_samples()
    end
end