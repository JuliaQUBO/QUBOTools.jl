# -*- :: Domains :: -*- #
abstract type VariableDomain end

@doc raw"""
    SpinDomain <: VariableDomain

```math
s \in \{-1, 1\}
```
""" struct SpinDomain <: VariableDomain end
@doc raw"""
    BoolDomain <: VariableDomain

```math
x \in \{0, 1\}
```
""" struct BoolDomain <: VariableDomain end

# -*- :: Models :: -*- #
abstract type AbstractQUBOModel{D<:VariableDomain} end

# ~*~ Validation ~*~ #
function Base.isvalid(::AbstractQUBOModel)
    false
end

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