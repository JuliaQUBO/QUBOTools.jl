@doc raw"""
    Qubist{D<:SpinDomain}

""" struct Qubist <: AbstractFormat end

domain(::Qubist) = SpinDomain

infer_format(::Val{:qh}) = Qubist()

include("parser.jl")
include("printer.jl")