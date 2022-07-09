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
include(joinpath("backend", "sampleset.jl"))
include(joinpath("backend", "standard.jl"))

include(joinpath("models", "bqpjson.jl"))
# include(joinpath("models", "hfs.jl"))
# include(joinpath("models", "minizinc.jl"))
# include(joinpath("models", "qubist.jl"))
# include(joinpath("models", "qubo.jl"))

# include(joinpath("bridges", "bqpjson_qubo.jl"))
# include(joinpath("bridges", "bqpjson_qubist.jl"))

end # module
