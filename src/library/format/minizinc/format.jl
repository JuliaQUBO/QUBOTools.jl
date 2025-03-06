raw"""
    Format{:minizinc}()
"""
function Format{:minizinc}()
    return Format{:minizinc}(Dict{Symbol,Any}())
end

infer_format(::Val{:mzn}) = Format{:minizinc}()

include("printer.jl")
