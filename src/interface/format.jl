@doc raw"""
    AbstractFormat

"""
abstract type AbstractFormat end

@doc raw"""
    AbstractStyle

"""
abstract type AbstractStyle end

@doc raw"""
    style(fmt::AbstractFormat)::Union{Symbol,Nothing}
"""
function style end

@doc raw"""
    format(::AbstractString)::AbstractFormat
    format(::Symbol)::AbstractFormat
    format(::Symbol, ::Symbol)::AbstractFormat

Given the file path, tries to infer the type associated to a QUBO model format.
"""
function format end
