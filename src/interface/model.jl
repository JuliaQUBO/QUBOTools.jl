# -*- :: Models :: -*- #
abstract type AbstractQUBOModel{D<:VariableDomain} end

# ~*~ Validation ~*~ #
Base.isvalid(::AbstractQUBOModel) = false

@doc raw"""
    __isvalidbridge(source::M, target::M, ::Type{<:AbstractQUBOModel}; kws...) where M <: AbstractQUBOModel

Checks if the `source` model is equivalent to the `target` reference modulo the given origin type.
Key-word arguments `kws...` are passed to interal `isapprox(::T, ::T; kws...)` calls.

""" function __isvalidbridge end

QUBOTools.__isvalidbridge(
    source::M,
    target::M,
    ::Type{<:AbstractQUBOModel};
    kws...
) where {M<:AbstractQUBOModel} = false