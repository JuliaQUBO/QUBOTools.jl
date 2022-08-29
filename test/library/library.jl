include("error.jl")
include("tools.jl")

function test_library()
    @testset "-*- Library" verbose = true begin
        test_error()
        test_tools()
    end
end