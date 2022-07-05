using Test
using BQPIO

include("bqpjson.jl")
include("bridges.jl")

function test_main()
    test_bqpjson()
    test_bridges()
end

test_main() # Here we go!