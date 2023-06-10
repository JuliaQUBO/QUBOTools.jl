@doc raw"""
    AbstractFormat{S}

"""
abstract type AbstractFormat{S} end

@doc raw"""
    AbstractStyle
"""
abstract type AbstractStyle end

@doc raw"""
    style(fmt::AbstractFormat{S})::S where {S<:Union{AbstractStyle,Nothing}}
"""
function style end

@doc raw"""
    format(::AbstractString)::AbstractFormat{S}
    format(::Symbol)::AbstractFormat{S}
    format(::Symbol, ::Symbol)::AbstractFormat{S}

Given the file path, tries to infer the type associated to a QUBO model format.
"""
function format end
