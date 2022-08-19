module QUBO

using Printf
using JSON
using JSONSchema

export BoolDomain, SpinDomain
export StandardQUBOModel
export BQPJSON
export Qubist
export QUBO
export MiniZinc

include("error.jl")
include("interface/model.jl")
include("interface/data.jl")
include("interface/io.jl")
include("tools.jl")

include("backend/sampleset.jl")
include("backend/model/model.jl")
include("backend/model/data.jl")
include("backend/model/io.jl")

include("models/models.jl")

include("bridges/bqpjson_minizinc.jl")
include("bridges/bqpjson_qubist.jl")
include("bridges/bqpjson_qubo.jl")

end # module