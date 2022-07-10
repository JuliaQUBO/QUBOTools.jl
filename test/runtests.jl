using Test
using Printf
using BQPIO

# ~*~ Include test functions ~*~
include("models/bqpjson.jl")

function test_data(path::String; n::Integer = 2)
    test_bqpjson(path; n = n)
end

function test_main()
    test_data(@__DIR__; n = 2)
end

test_main() # Here we go!