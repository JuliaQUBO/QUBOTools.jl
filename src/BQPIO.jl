module BQPIO

using JSON
using JSONSchema

export BoolDomain, SpinDomain
export StandardBQPModel
export BQPJSON
export Qubist
export QUBO
export MiniZinc

include("error.jl")
include("interface.jl")
include("tools.jl")
include("backend/sampleset.jl")
include("backend/standard.jl")

include("models/bqpjson.jl")
# include(joinpath("models", "hfs.jl"))
# include(joinpath("models", "minizinc.jl"))
# include(joinpath("models", "qubist.jl"))
include("models/qubo.jl")

# include(joinpath("bridges", "bqpjson_qubist.jl"))
include("bridges/bqpjson_qubo.jl")

end # module
