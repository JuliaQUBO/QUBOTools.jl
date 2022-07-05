module BQPIO

using JSON
using JSONSchema

export BoolDomain, SpinDomain
export BQPJSON
export Qubist
export QUBO

include("error.jl")
# include("samples.jl")
include("interface.jl")

# include(joinpath("models", "bqp.jl"))
include(joinpath("models", "bqpjson.jl"))
# include(joinpath("models", "hfs.jl"))
# include(joinpath("models", "minizinc.jl"))
# include(joinpath("models", "qubist.jl"))
include(joinpath("models", "qubo.jl"))

include(joinpath("bridges", "bqpjson_qubo.jl"))

end # module
