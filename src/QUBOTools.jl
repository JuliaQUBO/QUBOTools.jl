module QUBOTools

using Printf
using JSON
using JSONSchema

# ~*~ Variable Domains ~*~ #
export BoolDomain, SpinDomain

# ~*~ Supported Model Formats ~*~ #
export BQPJSON
export HFS
export MiniZinc
export Qubist
export QUBO

# ~*~ Package internal library ~*~ $
include("library/error.jl")
include("library/types.jl")
include("library/tools.jl")
include("library/sampleset.jl")

# ~*~ Interface definitions ~*~ $
include("interface/data.jl")
include("interface/io.jl")

# ~*~ Methods for the abstract model ~*~ #
include("abstract/data.jl")
include("abstract/io.jl")

# ~*~ Fallback methods ~*~ #
include("fallback/fallback.jl")

# ~*~ Standard backend implementation ~*~ #
include("backend/backend.jl")

# ~*~ Model implementation ~*~ #
include("models/models.jl")

# ~*~ Bridges between formats ~*~ #
include("bridges/bridges.jl")

end # module