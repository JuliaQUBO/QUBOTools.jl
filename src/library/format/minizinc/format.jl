@doc raw"""
    Format{:minizinc}()
"""
const minizinc_fmt = Format{:minizinc}

Format{:minizinc}() = Format{:minizinc}(Dict{Symbol,Any}())

infer_format(::Val{:mzn}) = Format{:minizinc}()

include("printer.jl")
