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

    function QUBO(
        dom::Domain                      = BoolDomain();
        sty::Union{Style,Symbol,Nothing} = :dwave,
        comment::Union{String,Nothing}   = nothing,
    )
        supports_style(QUBO, dom) || unsupported_style_error(QUBO, dom)
        supports_domain(QUBO, dom) || unsupported_domain_error(QUBO, dom)

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

supports_domain(::Type{QUBO}, ::Val{BoolDomain}) = true

infer_format(::Val{:qubo})                 = QUBO()
infer_format(::Val{:dwave}, ::Val{:qubo})  = QUBO(; style = :dwave)
infer_format(::Val{:qbsolv}, ::Val{:qubo}) = QUBO(; style = :dwave)
infer_format(::Val{:mqlib}, ::Val{:qubo})  = QUBO(; style = :mqlib)

include("parser.jl")
include("printer.jl")