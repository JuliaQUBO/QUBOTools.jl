@doc raw"""
    Qubist{D<:SpinDomain}

""" struct Qubist{D<:𝕊} <: AbstractFormat{D} end

Qubist(args...; kws...) = Qubist{𝕊}(args...; kws...)

infer_format(::Val{:qh}) = Qubist()

include("parser.jl")
include("printer.jl")