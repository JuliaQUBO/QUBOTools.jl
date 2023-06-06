module QUBOTools

using Printf
using JSON
using JSONSchema
using LinearAlgebra
using SparseArrays
using Statistics
using RecipesBase
using PseudoBooleanOptimization
using PseudoBooleanOptimization: varlt
const PBO = PseudoBooleanOptimization

const ↑ = -1 # \uparrow[tab]
const ↓ = +1 # \downarrow[tab]

# Exports: Symbols
export ↑, ↓
export 𝔹, 𝕊

# Exports: Variable Domains
export BoolDomain, SpinDomain

# Exports: Solution Interface
export Sample, SampleSet

# Exports: Supported Model Formats
export BQPJSON
export HFS
export MiniZinc
export Qubist
export QUBO

# Interface definitions
include("interface/form.jl")
include("interface/model.jl")
include("interface/solution.jl")
include("interface/format.jl")
include("interface/architecture.jl")
# include("interface/device.jl")
include("interface/generic.jl")
include("interface/fallback.jl")

# Error types and messages
include("library/error.jl")

# Reference implementations
include("library/form/abstract.jl")
include("library/form/form.jl")
include("library/form/cast.jl")

include("library/solution/abstract.jl")
include("library/solution/state.jl")
include("library/solution/sample.jl")
include("library/solution/sampleset.jl")

include("library/model/abstract.jl")
include("library/model/model.jl")
include("library/model/data.jl")

end # module