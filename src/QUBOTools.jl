module QUBOTools

using Printf
using JSON
using JSONSchema

# ~*~ Variable comparison ~*~ #
@doc raw"""
    varcmp(x::V, y::V) where {V}

This function exists to define an arbitrary ordering for a given type and was created to address [1].
There is no predefined comparison between instances MOI's `VariableIndex` type.
[1] https://github.com/jump-dev/MathOptInterface.jl/issues/1985
""" function varcmp end

varcmp(x::V, y::V) where {V} = isless(x, y)

const ≺ = varcmp # \prec[tab]

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