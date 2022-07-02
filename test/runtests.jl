using Test
import BQPIO

include("samples.jl")
include("bqpjson.jl")

function main()
    test_samples()
    test_bqpjson()
end

main() # Here we go!