using Test
using Printf
using QUBOTools

# ~*~ Include test functions ~*~
include("library/error.jl")
include("library/tools.jl")
include("models/models.jl")
include("bridges/bridges.jl")

function test_main(path::String, n::Integer)
    @testset "~*~*~ QUBOTools.jl ~*~*~" verbose = true begin
        test_error()
        test_tools()
        test_models(path, n)
        test_bridges(path, n)
    end
end

test_main(@__DIR__, 2) # Here we go!