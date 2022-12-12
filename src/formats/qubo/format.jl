@doc raw"""
    QUBO{D}(;
        style::Union{Symbol,Nothing} = nothing,
        comment::Union{String,Nothing} = nothing,
    ) where {D}

### References
[1] [qbsolv docs](https://docs.ocean.dwavesys.com/projects/qbsolv/en/latest/source/format.html)
""" struct QUBO{D<:𝔹} <: AbstractFormat{D}
    style::Union{Symbol,Nothing}
    comment::Union{String,Nothing}

    function QUBO{D}(;
        style::Union{Symbol,Nothing} = :dwave,
        comment::Union{String,Nothing} = nothing,
    ) where {D}
        if !isnothing(style) && isnothing(comment)
            if style === :dwave
                comment = "c"
            elseif style === :mqlib
                comment = "#"
            else
                format_error("Unknown QUBO File style '$style'")
            end
        end

        return new{D}(style, comment)
    end
end

QUBO(args...; kws...) = QUBO{𝔹}(args...; kws...)

infer_format(::Val{:qubo}) = QUBO()

include("parser.jl")
include("printer.jl")