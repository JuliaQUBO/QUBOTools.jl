include("bqpjson_minizinc.jl")
include("bqpjson_qubist.jl")
include("bqpjson_qubo.jl")

function test_bridges()
    @testset "-*- Bridges -*-" verbose = true begin
        # test_bqpjson_minizinc()
        test_bqpjson_qubist()
        # test_bqpjson_qubo()
    end
end