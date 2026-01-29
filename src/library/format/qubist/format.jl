@doc raw"""
    Format{:qubist}()

Simple spin-based file format.
"""
const qubist_fmt = Format{:qubist}

Format{:qubist}() = Format{:qubist}(Dict{Symbol,Any}())

infer_format(::Val{:qh}) = Format{:qubist}()

include("parser.jl")
include("printer.jl")
