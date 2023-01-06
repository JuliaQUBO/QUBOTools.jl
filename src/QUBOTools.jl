module QUBOTools

using Printf
using JSON
using JSONSchema
using SparseArrays
using RecipesBase
using Base: @propagate_inbounds
using InteractiveUtils: subtypes

# ~*~ Variable comparison ~*~ #
@doc raw"""
    varlt(x::V, y::V) where {V}

This function exists to define an arbitrary ordering for a given type and was created to address [1].
There is no predefined comparison between instances MOI's `VariableIndex` type.
[1] https://github.com/jump-dev/MathOptInterface.jl/issues/1985
""" function varlt end

varlt(x::V, y::V) where {V} = isless(x, y)

const ≺ = varlt # \prec[tab]
const ↑ = -1     # \uparrow[tab]
const ↓ = +1     # \downarrow[tab]

# ~*~ Exports: Symbols ~*~ #
export ↑, ↓
export 𝔹, 𝕊

# ~*~ Exports: Variable Domains ~*~ #
export BoolDomain, SpinDomain

# ~*~ Exports: Solution Interface ~*~ #
export Sample, SampleSet

# ~*~ Exports: Supported Model Formats ~*~ #
export Standard
export BQPJSON
export HFS
export MiniZinc
export Qubist
export QUBO

# ~*~ Interface definitions ~*~ #
include("interface/interface.jl")

# ~*~ Fallback methods ~*~ #
include("interface/fallback.jl")

# ~*~ Generic methods ~*~ #
include("interface/generic.jl")

# ~*~ Package internal library ~*~ #
include("library/error.jl")
include("library/tools.jl")
include("library/sampleset.jl")

# ~*~ Model definitions ~*~ #
include("model/model.jl")
include("model/abstract.jl")

# ~*~ Format definitions ~*~ #
include("formats/formats.jl")

# ~*~ Analysis Tools ~*~ #
include("analysis/interface.jl")
include("analysis/time.jl")
include("analysis/metrics.jl")
include("analysis/plots.jl")

end # module