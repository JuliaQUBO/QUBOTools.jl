module QUBOTools

using Printf
using JSON
using JSONSchema

export BoolDomain, SpinDomain
export StandardQUBOModel
export BQPJSON
export Qubist
export QUBO
export MiniZinc

# ~*~ Package internal library ~*~
include("library/error.jl")
include("library/types.jl")
include("library/tools.jl")
include("library/sampleset.jl")

# ~*~ Interface definitions ~*~
include("interface/data.jl")
include("interface/io.jl")
include("interface/model.jl")

include("abstract/data.jl")
include("abstract/io.jl")

include("fallback/data.jl")

include("backend/model.jl")
include("backend/data.jl")
include("backend/io.jl")

include("models/models.jl")

# include("bridges/bqpjson_minizinc.jl")
# include("bridges/bqpjson_qubist.jl")
# include("bridges/bqpjson_qubo.jl")

end # module