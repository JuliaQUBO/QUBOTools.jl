raw"""
    Format{:qubist}()

Simple spin-based file format.
"""
function Format{:qubist}()
    return Format{:qubist}(Dict{Symbol,Any}())
end

infer_format(::Val{:qh}) = Format{:qubist}()

include("parser.jl")
include("printer.jl")
