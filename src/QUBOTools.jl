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
export 𝔹, 𝕊

# ~*~ Exports: Variable Domains ~*~ #
export BoolDomain, SpinDomain

# ~*~ Exports: Solution Interface ~*~ #
export Sample, SampleSet, SamplePool

# ~*~ Exports: Supported Model Formats ~*~ #
export BQPJSON
export HFS
export MiniZinc
export Qubist
export QUBO

# ~*~ Interface definitions ~*~ #
include("interface.jl")

# ~*~ Fallback methods ~*~ #
include("fallback.jl")

# ~*~ Generic methods ~*~ #
include("generic.jl")

# ~*~ Package internal library ~*~ #
include("library/error.jl")
include("library/types.jl")
include("library/tools.jl")
include("library/sampleset.jl")

# ~*~ Model definitions ~*~ #
include("models/abstract/model.jl")
include("models/standard/model.jl")
include("models/qubo/model.jl")
include("models/bqpjson/model.jl")
include("models/hfs/model.jl")
include("models/minizinc/model.jl")
include("models/qubist/model.jl")

# ~*~ Bridges between formats ~*~ #
include("bridges/bridges.jl")
include("bridges/bqpjson.jl")
include("bridges/hfs.jl")
include("bridges/minizinc.jl")
include("bridges/qubist.jl")
include("bridges/qubo.jl")


# ~*~ Analysis Tools ~*~ #
include("analysis/interface.jl")
include("analysis/time.jl")
include("analysis/metrics.jl")
include("analysis/plots.jl")

end # module