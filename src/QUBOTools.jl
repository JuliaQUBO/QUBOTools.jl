module QUBOTools

using Printf
using JSON
using JSONSchema
using Graphs
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

# Interface definitions
include("interface/form.jl")
include("interface/model.jl")
include("interface/solution.jl")
include("interface/format.jl")
include("interface/architecture.jl")
# include("interface/device.jl")
include("interface/analysis.jl")
include("interface/generic.jl")
include("interface/fallback.jl")

# Error types and messages
include("library/error.jl")

# Reference implementations
include("library/io.jl")

include("library/frame.jl")
include("library/form/abstract.jl")
include("library/form/dict.jl")
include("library/form/dense.jl")
include("library/form/sparse.jl")

include("library/solution/abstract.jl")
include("library/solution/state.jl")
include("library/solution/sample.jl")
include("library/solution/sampleset.jl")

include("library/model/abstract.jl")
include("library/model/model.jl")

include("library/format/abstract.jl")
include("library/format/bqpjson/format.jl")
# include("library/format/hfs/format.jl")
# include("library/format/minizinc/format.jl")
# include("library/format/qubist/format.jl")
include("library/format/qubo/format.jl")

include("library/analysis/metrics/solution.jl")
include("library/analysis/metrics/model.jl")

include("library/analysis/visualization/energy_frequency.jl")
include("library/analysis/visualization/model_density.jl")

end # module