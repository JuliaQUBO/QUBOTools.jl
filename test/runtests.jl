using Test
using Printf
using BQPIO

# ~*~ Include test functions ~*~
include("models/bqpjson.jl")
include("models/qubist.jl")
include("models/qubo.jl")

function test_models(path::String, n::Integer)
    @testset "Models" verbose = true begin
        test_bqpjson(path, n)
        test_qubist(path, n)
        test_qubo(path, n)
    end
end

function test_bridges(path::String, n::Integer)
    @testset "Bridges" verbose = true begin
        
    end
end

function test_main(path::String, n::Integer)
    test_models(path, n)
    test_bridges(path, n)
end

test_main(@__DIR__, 2) # Here we go!