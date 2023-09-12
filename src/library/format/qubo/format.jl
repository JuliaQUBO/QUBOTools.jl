@doc raw"""
    QUBO()
    QUBO(style::Symbol)
"""
struct QUBO <: AbstractFormat
    style::Union{Symbol,Nothing}

    function QUBO(style::Union{Symbol,Nothing})
        if isnothing(style)
            return new(nothing)
        elseif style === :dwave || style === :qbsolv
            return new(:dwave)
        elseif style === :mqlib
            return new(:mqlib)
        else
            error("Unkown style '$style' for QUBO files. Options are: ':dwave', ':qbsolv' and ':mqlib'.")

            return nothing
        end
    end
end

format(::Val{:dwave})  = QUBO(:dwave)
format(::Val{:mqlib})  = QUBO(:mqlib)
format(::Val{:qbsolv}) = QUBO(:qbsolv)
format(::Val{:qubo})   = QUBO(:dwave) # defaults to dwave style

include("parser.jl")
include("printer.jl")
