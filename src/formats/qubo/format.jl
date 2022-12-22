@doc raw"""
    QUBO{D}(;
        style::Union{Symbol,Nothing} = nothing,
        comment::Union{String,Nothing} = nothing,
    ) where {D}

### References
[1] [qbsolv docs](https://docs.ocean.dwavesys.com/projects/qbsolv/en/latest/source/format.html)
""" struct QUBO <: AbstractFormat
    style::Union{Symbol,Nothing}
    comment::Union{String,Nothing}

    function QUBO(;
        style::Union{Symbol,Nothing} = :dwave,
        comment::Union{String,Nothing} = nothing,
    )
        if !isnothing(style) && isnothing(comment)
            if style === :dwave
                comment = "c"
            elseif style === :mqlib
                comment = "#"
            else
                format_error("Unknown QUBO File style '$style'")
            end
        end

        return new(style, comment)
    end
end

domain(::QUBO) = BoolDomain

infer_format(::Val{:qubo}) = QUBO()

include("parser.jl")
include("printer.jl")