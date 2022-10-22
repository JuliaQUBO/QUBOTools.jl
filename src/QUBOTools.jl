module QUBOTools

using Printf
using JSON
using JSONSchema
using SparseArrays
using RecipesBase
using Base: @propagate_inbounds

# ~*~ Variable comparison ~*~ #
@doc raw"""
    varcmp(x::V, y::V) where {V}

This function exists to define an arbitrary ordering for a given type and was created to address [1].
There is no predefined comparison between instances MOI's `VariableIndex` type.
[1] https://github.com/jump-dev/MathOptInterface.jl/issues/1985
""" function varcmp end

varcmp(x::V, y::V) where {V} = isless(x, y)

const ≺ = varcmp # \prec[tab]
const ↑ = -1     # \uparrow[tab]
const ↓ = +1     # \downarrow[tab]

# ~*~ Exports: Symbols ~*~ #
export ↑, ↓

# ~*~ Exports: Variable Domains ~*~ #
export BoolDomain, SpinDomain

# ~*~ Exports: Solution Interface ~*~ #
export SampleSet, Sample

# ~*~ Exports: Supported Model Formats ~*~ #
export BQPJSON
export HFS
export MiniZinc
export Qubist
export QUBO

# ~*~ Package internal library ~*~ #
include("library/error.jl")
include("library/types.jl")
include("library/tools.jl")
include("library/samples/samples.jl")

# ~*~ Interface definitions ~*~ #
include("interface/interface.jl")

# ~*~ Methods for the abstract model ~*~ #
include("interface/abstract.jl")

# ~*~ Fallback methods ~*~ #
include("interface/fallback.jl")

# ~*~ Concrete methods ~*~ #
include("interface/concrete.jl")

# ~*~ Model implementation ~*~ #
include("models/models.jl")

# ~*~ Bridges between formats ~*~ #
include("bridges/bridges.jl")

# ~*~ Analysis Tools ~*~ #
include("analysis/interface.jl")
include("analysis/time.jl")
include("analysis/metrics.jl")
include("analysis/plots.jl")

end # module