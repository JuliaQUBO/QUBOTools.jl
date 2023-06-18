@doc raw"""
    AbstractForm{T}

A form is a 5-tuple ``(n, \ell, Q, \alpha, \beta)`` representing a raw QUBO / Ising model.

- ``n``, the dimension, is the number of variables.
- ``\ell``, the linear form, is a vector with the linear terms.
- ``Q``, the quadratic form, is an upper triangular matrix containing the quadratic relations.
- ``\alpha`` is the scale factor.
- ``\beta`` is the offset factor.

The inner data structures used to represent each of these elements may vary.
"""
abstract type AbstractForm{T} end

@doc raw"""
    form(::Any)
"""
function form end

@doc raw"""
    linear_form
"""
function linear_form end

@doc raw"""
    quadratic_form
"""
function quadratic_form end
