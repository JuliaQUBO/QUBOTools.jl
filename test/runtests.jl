using Test
using Printf
using BQPIO

# ~*~ Include test functions ~*~
include("models/bqpjson.jl")
include("models/qubo.jl")

function test_data(path::String, n::Integer)
    @testset "Models" verbose = true begin
        test_bqpjson(path, n)
        test_qubo(path, n)
    end
end

function test_main(n::Integer = 2)
    test_data(@__DIR__, n)
end

test_main() # Here we go!