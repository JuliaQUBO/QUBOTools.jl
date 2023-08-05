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
    QUBO{DWaveStyle}()
    QUBO{MQLibStyle}()

"""
struct QUBO{S} <: AbstractFormat{S}

    QUBO() = new{nothing}()

    QUBO{S}() where {S} = new{S}()
end

domain(::QUBO) = 𝔹

format(::Val{:dwave}, ::Val{:qubo})  = QUBO{DWaveStyle}()
format(::Val{:mqlib}, ::Val{:qubo})  = QUBO{MQLibStyle}()
format(::Val{:qbsolv}, ::Val{:qubo}) = QUBO{DWaveStyle}()
format(::Val{:qubo})                 = QUBO()

include("parser.jl")
include("printer.jl")
