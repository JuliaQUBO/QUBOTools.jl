@doc raw"""
    AbstractForm{T}

A form is a ``7``-tuple ``(n, \ell, Q, \alpha, \beta) \times (\textrm{sense}, \textrm{domain})``
representing a QUBO / Ising model.

- ``n``, the dimension, is the number of variables.
- ``\mathbf{\ell}``, the linear form, represents a vector storing the linear terms.
- ``\mathbf{Q}``, the quadratic form, represents an upper triangular matrix containing the quadratic interactions.
- ``\alpha`` is the scale factor, defaults to ``1``.
- ``\beta`` is the offset factor, defaults to ``0``.

The inner data structures used to represent each of these elements may vary.
"""
abstract type AbstractForm{T} end

@doc raw"""
    form(src [, formtype::Type{<:AbstractForm{T}}]; sense, domain) where {T}
    form(src [, formtype::Union{Symbol,Type}, T::Type = Float64]; sense, domain)

Returns the QUBO form stored within `src`, casting it to the corresponding (`sense`, `domain`)
frame and, if necessary, converting the coefficients to type `T`.

The underlying data structure is given by `formtype`.
Current options include `:dict`, `:dense` and `:sparse`.

For more informaion, see [`QUBOTools.Form`](@ref) and [`QUBOTools.AbstractForm`](@ref).
"""
function form end

@doc raw"""
    formtype(spec::Type)
    formtype(spec::Symbol)

Returns a form type according to the given specification.

    formtype(src)

Returns the form type of a form or model.
"""
function formtype end

@doc raw"""
    AbstractLinearForm{T}

Linear form subtypes will create a wrapper around data structures for
representing the linear terms ``\mathbf{\ell}'\mathbf{x}`` of the QUBO
model.
"""
abstract type AbstractLinearForm{T} end

@doc raw"""
    linear_form(Φ::F) where {T,F<:AbstractForm{T}}

Returns the linear part of the QUBO form.
"""
function linear_form end

@doc raw"""
    AbstractQuadraticForm{T}

Quadratic form subtypes will create a wrapper around data structures for
representing the quadratic terms ``\mathbf{x}'\mathbf{Q}\,\mathbf{x}`` of
the QUBO model.
"""
abstract type AbstractQuadraticForm{T} end

@doc raw"""
    quadratic_form(Φ::F) where {T,F<:AbstractForm{T}}

Returns the quadratic part of the QUBO form.
"""
function quadratic_form end

@doc raw"""
    fix_variables(Φ::AbstractForm, fix::AbstractDict{<:Integer})

Fixes variables in `Φ` to the values supplied by `fix`.
Keys are original form indices in `1:dimension(Φ)`, not model variable labels.

For boolean forms, fixed values must belong to ``\mathbb{B} = \{0, 1\}``.
For spin forms, fixed values must belong to ``\mathbb{S} = \{-1, 1\}``.

Returns `(Φ_reduced, offset_delta, index_map)`, where `offset_delta` is the
unscaled amount added to `offset(Φ)` and `index_map` maps each surviving
original variable index to its dense index in `Φ_reduced`.
Surviving indices retain their original order, including isolated variables.
The storage types, scale, objective sense and domain are preserved.

For every valid reduced state `y`, with
`x = lift_state(y, fix, index_map, dimension(Φ))`, the energy identity is
`value(x, Φ) ≈ value(y, Φ_reduced)` (up to floating-point roundoff).
The reduced offset is already `offset(Φ) + offset_delta`: do not add the
delta again to the reduced energy. The corresponding full-energy change in
the constant term is `scale(Φ) * offset_delta`.

An empty `fix` preserves all variables; fixing every variable returns a
zero-dimensional form containing the full constant energy. Out-of-range
indices or values outside the form's domain throw `ArgumentError`.
See the [conditioning example](@ref variable-conditioning) for label mapping.
"""
function fix_variables end

@doc raw"""
    lift_state(state_reduced, fix, index_map, n)

Reconstructs a full length-`n` state from a reduced state, fixed variable
values, and the `index_map` returned by [`QUBOTools.fix_variables`](@ref).
The map direction is original index → reduced index. Fixed indices and map
keys must partition `1:n`, and map values must be a bijection onto the reduced
state positions; invalid dimensions or mappings throw `ArgumentError`.
This function checks reconstruction structure, not domain membership: reuse
the validated `fix` and a reduced state valid for the reduced form.
"""
function lift_state end


@doc raw"""
    qubo(args; kws...)

This function is a shorthand for `form(args...; kws..., domain = :bool)`.

For more informaion, see [`QUBOTools.form`](@ref).
"""
function qubo end

@doc raw"""
    ising(args; kws...)
    
This function is a shorthand for `form(args...; kws..., domain = :spin)`.

For more informaion, see [`QUBOTools.form`](@ref).
"""
function ising end
