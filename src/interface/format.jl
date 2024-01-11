@doc raw"""
    AbstractFormat

"""
abstract type AbstractFormat end

@doc raw"""
    format(::AbstractString)::AbstractFormat
    format(::Symbol)::AbstractFormat
    format(::Symbol, ::Symbol)::AbstractFormat

Given the file path, tries to infer the type associated to a QUBO model format.
"""
function format end
