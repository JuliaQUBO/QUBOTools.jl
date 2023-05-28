@doc raw"""
    AbstractFormat{S}

"""
abstract type AbstractFormat{S} end

@doc raw"""
    Style

"""
abstract type Style end

@doc raw"""
    style(fmt::AbstractFormat{S})::Style
"""
function style end

@doc raw"""
    infer_format(::AbstractString)::AbstractFormat{S}
    infer_format(::Symbol)::AbstractFormat{S}
    infer_format(::Symbol, ::Symbol)::AbstractFormat{S}

Given the file path, tries to infer the type associated to a QUBO model format.
"""
function infer_format end
