""" /src/interface/data.jl @ QUBOTools.jl

    This files contains iterfaces for data access within QUBO's format system.
    
    It also contains a few ones for executing queries on models.
"""

@doc raw"""
    backend(model)

""" function backend end

@doc raw"""
    model_name(model)

""" function model_name end

@doc raw"""
    domain_name(model)

""" function domain_name end

@doc raw"""
    offset(model)

""" function offset end

@doc raw"""
    scale(model)

""" function scale end

@doc raw"""
    id(model)
""" function id end

@doc raw"""
    version(model)
""" function version end

@doc raw"""
    description(model)
""" function description end

@doc raw"""
    metadata(model)
""" function metadata end

@doc raw"""
    sampleset(model)
""" function sampleset end

@doc raw"""
    linear_terms(model)
    linear_terms(model; explicit::Bool)

Retrieves the linear terms of a model as a dict.

The `explicit` keyword includes all variables, breaking sparsity.

""" function linear_terms end

@doc raw"""
""" function quadratic_terms end

@doc raw"""
""" function variables end

@doc raw"""
""" function variable_set end

@doc raw"""
    variable_map(model)
    variable_map(model, x)

""" function variable_map end

@doc raw"""
    variable_inv(model)
    variable_inv(model, i)
""" function variable_inv end

@doc raw"""
    qubo(model::AbstractQUBOModel{<:BoolDomain})
    qubo(::Type{<:Dict}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    qubo(::Type{<:Array}, T::Type, model::AbstractQUBOModel{<:BoolDomain})

# QUBO Normal Form

```math
f(\vec{x}) = \alpha \left[{ \vec{x}'\,Q\,\vec{x} + \beta }\right]
```

Returns a quadruple ``(x, Q, \alpha, \beta)`` where:
 * `x::Dict{S, Int}` maps each of the model's variables to an integer index, to be used when interacting with `Q`.
 * `Q::Dict{Tuple{Int, Int}, T}` is a sparse representation of the QUBO Matrix.
 * `α::T` is the scaling factor.
 * `β::T` is the offset constant.
""" function qubo end

@doc raw"""
    ising(model::AbstractQUBOModel{<:SpinDomain})
    ising(::Type{<:Dict}, model::AbstractQUBOModel{<:SpinDomain})
    ising(::Type{<:Array}, model::AbstractQUBOModel{<:SpinDomain})

# Ising Normal Form

```math
H(\vec{s}) = \alpha \left[{ \vec{s}'\,J\,\vec{s} + \vec{h}\,\vec{s} + \beta }\right]
```

Returns a quintuple ``(s, h, J, \alpha, \beta)`` where:
* `s::Dict{S, Int}` maps each of the model's variables to an integer index, to be used when interacting with ``h`` and ``J``.
* `h::Dict{Int, T}` is a sparse vector for the linear terms of the Ising Model.
* `J::Dict{Tuple{Int, Int}, T}` is a sparse representation of the quadratic magnetic interactions.
* `α::T` is the scaling factor.
* `β::T` is the offset constant.
""" function ising end

@doc raw"""
    energy(state, model)

This function aims to evaluate the energy of a given state under some QUBO Model.
**Note:** Scale and offset factors are taken into account.
""" function energy end

# ~*~ Sizes & Dimensions ~*~ #
@doc raw"""
""" function domain_size end

@doc raw"""
""" function linear_size end

@doc raw"""
""" function quadratic_size end

@doc raw"""
""" function density end

@doc raw"""
""" function linear_density end

@doc raw"""
""" function quadratic_density end