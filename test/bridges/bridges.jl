include("BQPJSON_minizinc.jl")
include("BQPJSON_qubist.jl")
include("BQPJSON_QUBOTools.jl")

function test_bridges(path::String, n::Integer)
    @testset "-*- Bridges -*-" verbose = true begin
        test_BQPJSON_minizinc(path, n)
        test_BQPJSON_qubist(path, n)
        test_BQPJSON_qubo(path, n)
    end
end