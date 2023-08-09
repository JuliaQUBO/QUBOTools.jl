@doc raw"""
    Qubist()

"""
struct Qubist <: AbstractFormat end

format(::Val{:qh}) = Qubist()

include("parser.jl")
include("printer.jl")
