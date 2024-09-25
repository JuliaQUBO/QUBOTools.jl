module QUBOTools

import Printf
import HDF5
import JSON
import JSONSchema
import NetworkLayout
import TOML

using Graphs
using GeometryBasics
using LinearAlgebra
using SparseArrays
using Statistics
using RecipesBase
using Random

import PseudoBooleanOptimization as PBO
import PseudoBooleanOptimization: varlt, varshow

const __PROJECT__ = Ref{Union{String,Nothing}}(nothing)

function __project__()
    if isnothing(__PROJECT__[])
        proj_path = abspath(dirname(@__DIR__))
    
        @assert isdir(proj_path)
    
        __PROJECT__[] = proj_path
    end

    return __PROJECT__[]::String
end

const __VERSION__ = Ref{Union{VersionNumber,Nothing}}(nothing)

function __version__()::VersionNumber
    if isnothing(__VERSION__[])
        proj_file_path = abspath(__project__(), "Project.toml")

        @assert isfile(proj_file_path)

        proj_file_data = TOML.parsefile(proj_file_path)

        __VERSION__[] = VersionNumber(proj_file_data["version"])
    end

    return __VERSION__[]::VersionNumber
end

const ↓ = -1 # \downarrow[tab]
const ↑ = +1 # \uparrow[tab]

# Exports: Symbols
export ↓, ↑, 𝔹, 𝕊

# Exports: Solution Interface
export Sample, SampleSet

# Interface definitions
include("interface/form.jl")
include("interface/model.jl")
include("interface/frame.jl")
include("interface/solution.jl")
include("interface/synthesis.jl")
include("interface/format.jl")
include("interface/architecture.jl")
include("interface/device.jl")
include("interface/layout.jl")
include("interface/analysis.jl")
include("interface/fallback.jl")

# Error types and messages
include("library/error.jl")

# Reference implementations
include("library/io.jl")
include("library/frame.jl")
include("library/layout.jl")

include("library/form/abstract.jl")
include("library/form/form.jl")
include("library/form/dict.jl")
include("library/form/dense.jl")
include("library/form/sparse.jl")

include("library/solution/abstract.jl")
include("library/solution/state.jl")
include("library/solution/sample.jl")
include("library/solution/sampleset.jl")

include("library/model/abstract.jl")
include("library/model/variable_map.jl")
include("library/model/model.jl")

include("library/synthesis/abstract.jl")
include("library/synthesis/sherrington_kirkpatrick.jl")
include("library/synthesis/wishart.jl")

include("library/format/abstract.jl")
include("library/format/bqpjson/format.jl")
include("library/format/minizinc/format.jl")
include("library/format/qubist/format.jl")
include("library/format/qubo/format.jl")
include("library/format/qubin/format.jl")

include("library/analysis/metrics/solution.jl")
include("library/analysis/metrics/model.jl")

include("library/architecture/abstract.jl")
include("library/architecture/generic.jl")

include("library/device/abstract.jl")
include("library/device/generic.jl")

include("library/analysis/visualization/abstract.jl")
include("library/analysis/visualization/energy_frequency.jl")
include("library/analysis/visualization/energy_distribution.jl")
include("library/analysis/visualization/model_density.jl")
include("library/analysis/visualization/system_layout.jl")

# Extras
include("extra/moi/num_reads.jl")
include("extra/moi/spin_set.jl")
include("extra/moi/qubo_model.jl")

end # module
