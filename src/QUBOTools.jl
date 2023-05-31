module QUBOTools

using Printf
using JSON
using JSONSchema
using LinearAlgebra
using SparseArrays
using RecipesBase
using PseudoBooleanOptimization

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

end # module