@doc raw"""
    DWaveStyle <: AbstractStyle

This style is used by some of the D-Wave libraries[^qbsolv].

[^qbsolv]: qbsolv Documentation [{docs}](https://docs.ocean.dwavesys.com/projects/qbsolv/en/latest/source/format.html)
"""
struct DWaveStyle <: AbstractStyle end

@doc raw"""
    MQLibStyle <: AbstractStyle

This is the style of the primary I/O format used to access the MQLib heuristic library.
"""
struct MQLibStyle <: AbstractStyle end

@doc raw"""
    QUBO()
    QUBO(style::AbstractStyle)

"""
struct QUBO{S} <: AbstractFormat{S}
    style::Union{S,Nothing}

    QUBO() = new{nothing}(nothing)

    QUBO(style::S) where {S<:AbstractStyle} = new{S}(style)
end

style(fmt::QUBO) = fmt.style

format(::Val{:dwave}, ::Val{:qubo})  = QUBO(DWaveStyle())
format(::Val{:mqlib}, ::Val{:qubo})  = QUBO(MQLibStyle())
format(::Val{:qbsolv}, ::Val{:qubo}) = QUBO(DWaveStyle())
format(::Val{:qubo})                 = QUBO()

include("parser.jl")
include("printer.jl")
