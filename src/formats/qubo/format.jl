@doc raw"""
    QUBO{D}(;
        style::Union{Symbol,Nothing} = nothing,
        comment::Union{String,Nothing} = nothing,
    ) where {D}

### References
[1] [qbsolv docs](https://docs.ocean.dwavesys.com/projects/qbsolv/en/latest/source/format.html)
""" struct QUBO{D<:BoolDomain} <: AbstractFormat{D}
    style::Union{Symbol,Nothing}
    comment::Union{String,Nothing}

    function QUBO{D}(;
        style::Union{Symbol,Nothing} = :dwave,
        comment::Union{String,Nothing} = nothing,
    ) where {D}
        if style === :dwave
            comment = "c"
        elseif style === :mqlib
            comment = "#"
        elseif !isnothing(style)
            format_error("Unknown QUBO File style '$style'")
        end

        return new{D}(style, comment)
    end
end

QUBO(args...; kws...) = QUBO{BoolDomain}(args...; kws...)

infer_format(::Val{:qubo}) = QUBO()

include("parser.jl")
include("printer.jl")