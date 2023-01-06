@doc raw"""
    QUBO{D}(;
        style::Union{Symbol,Nothing} = nothing,
        comment::Union{String,Nothing} = nothing,
    ) where {D}

### References
[1] [qbsolv docs](https://docs.ocean.dwavesys.com/projects/qbsolv/en/latest/source/format.html)
""" struct QUBO <: AbstractFormat
    style::Union{DWaveStyle,MQLibStyle,Nothing}
    comment::Union{String,Nothing}

    function QUBO(
        dom::BoolDomain                           = BoolDomain(),
        sty::Union{DWaveStyle,MQLibStyle,Nothing} = DWaveStyle();
        comment::Union{String,Nothing}            = nothing,
    )
        if !isnothing(sty) && isnothing(comment)
            if sty === DWaveStyle()
                comment = "c"
            elseif sty === MQLibStyle()
                comment = "#"
            end
        end

        return new(sty, comment)
    end
end

domain(::QUBO) = BoolDomain()

supports_domain(::Type{QUBO}, ::BoolDomain) = true

style(fmt::QUBO) = fmt.style

supports_style(::Type{QUBO}, ::DWaveStyle) = true
supports_style(::Type{QUBO}, ::MQLibStyle) = true

infer_format(::Val{:qubo})                 = QUBO(𝔹, nothing)
infer_format(::Val{:dwave}, ::Val{:qubo})  = QUBO(𝔹, Style(:dwave))
infer_format(::Val{:mqlib}, ::Val{:qubo})  = QUBO(𝔹, Style(:mqlib))
infer_format(::Val{:qbsolv}, ::Val{:qubo}) = QUBO(𝔹, Style(:dwave))

include("parser.jl")
include("printer.jl")
