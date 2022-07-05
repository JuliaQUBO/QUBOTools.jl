using Test
using BQPIO

# include("samples.jl")
include("bqpjson.jl")
include("bridges.jl")

function main()
    # test_samples()
    test_bqpjson()
    test_bridges()
end

main() # Here we go!