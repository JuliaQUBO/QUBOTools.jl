@doc raw"""
    MiniZinc
"""
struct MiniZinc <: AbstractFormat end

format(::Val{:mzn}) = MiniZinc()

include("printer.jl")
