""" /src/interface/data.jl @ QUBOTools.jl

    This files contains methods for data access within QUBO's format system.
    
    It also contains a few methods for query execution on models.
"""

@doc raw"""
    backend

""" function backend end

@doc raw"""
""" function model_name end

model_name(model::AbstractQUBOModel) = "QUBO"

@doc raw"""
""" function domain_name end

domain_name(model::AbstractQUBOModel{<:BoolDomain}) = "Bool"
domain_name(model::AbstractQUBOModel{<:SpinDomain}) = "Spin"

abstract type QUBOAttribute end

function getattr(model::Any, attr::QUBOAttribute)
    QUBOTools.getattr(QUBOTools.backend(model), attr)
end

function getdefaultattr(model::Any, attr::QUBOAttribute)
    value = QUBOTools.getattr(QUBOTools.backend(model), attr)

    if isnothing(value)
        QUBOTools._defaultattr(QUBOTools.backend(model), attr)
    else
        value
    end
end

_defaultattr(::Any, ::QUBOAttribute) = nothing

struct ATTR_OFFSET <: QUBOAttribute end

function offset(model::Any)
    getdefaultattr(model, ATTR_OFFSET())
end

struct ATTR_SCALE <: QUBOAttribute end

function scale(model::Any)
    getdefaultattr(model, ATTR_SCALE())
end

struct ATTR_ID <: QUBOAttribute end

function id(model::Any)
    getdefaultattr(model, ATTR_ID())
end

struct ATTR_VERSION <: QUBOAttribute end

function version(model::Any)
    getdefaultattr(model, ATTR_VERSION())
end

struct ATTR_DESCRIPTION <: QUBOAttribute end

function description(model::Any)
    getdefaultattr(model, ATTR_DESCRIPTION())
end

struct ATTR_METADATA <: QUBOAttribute end

function metadata(model::Any)
    getdefaultattr(model, ATTR_METADATA())
end

struct ATTR_SAMPLESET <: QUBOAttribute end

@doc raw"""
""" function sampleset end

function sampleset(model::Any)
    getdefaultattr(model, ATTR_SAMPLESET())
end

@doc raw"""
    linear_terms(model::Any)
    linear_terms(model::Any; explicit::Bool)

Retrieves the linear terms of a model as a dict.

The `explicit` keyword determines wether all variables should be included, breaking sparsity.

""" function linear_terms end

function linear_terms(model::Any; explicit::Bool=false)
    linear_terms = QUBOTools.linear_terms(QUBOTools.backend(model))

    if explicit
        return QUBOTools._explicit_linear_terms(
            linear_terms,
            QUBOTools.variable_inv(model)
        )
    else
        return linear_terms
    end
end

function _explicit_linear_terms(
    linear_terms::Dict{Int,T},
    variable_inv::Dict{Int,<:Any},
) where {T}
    merge(
        Dict{Int,T}(i => zero(T) for i in keys(variable_inv)),
        linear_terms,
    )
end

@doc raw"""
""" function quadratic_terms end

function quadratic_terms(model::Any)
    QUBOTools.quadratic_terms(QUBOTools.backend(model))
end

@doc raw"""
""" function variables end

function variables(model::Any)
    sort(collect(keys(QUBOTools.variable_map(model))))
end

@doc raw"""
""" function variable_set end

function variable_set(model::Any)
    Set(keys(QUBOTools.variable_map(model)))
end

@doc raw"""
""" function variable_map end

function variable_map(model::Any)
    QUBOTools.variable_map(QUBOTools.backend(model))
end

function variable_map(model::Any, i::Any)
    QUBOTools.variable_map(QUBOTools.backend(model), i)
end

@doc raw"""
""" function variable_inv end

function variable_inv(model::Any)
    QUBOTools.variable_inv(QUBOTools.backend(model))
end

function variable_inv(model::Any, i::Integer)
    QUBOTools.variable_inv(QUBOTools.backend(model), i)
end

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

function qubo(model::Any)
    QUBOTools.qubo(QUBOTools.backend(model))
end

function qubo(model::AbstractQUBOModel{<:BoolDomain})
    QUBOTools.qubo(Dict, Float64, model)
end

function qubo(::Type{<:Dict}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    x = QUBOTools.variable_map(model)
    Q = Dict{Tuple{Int,Int},T}()
    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, qᵢ) in QUBOTools.linear_terms(model)
        Q[i, i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (x, Q, α, β)
end

function qubo(::Type{<:Array}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    x = QUBOTools.variable_map(model)
    n = length(x)
    Q = zeros(T, n, n)
    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, qᵢ) in QUBOTools.linear_terms(model)
        Q[i, i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (x, Q, α, β)
end

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

function ising(model::Any)
    QUBOTools.ising(QUBOTools.backend(model))
end

function ising(model::AbstractQUBOModel{<:SpinDomain})
    QUBOTools.ising(Dict, model)
end

function ising(::Type{<:Dict}, model::AbstractQUBOModel{<:SpinDomain})
    s = QUBOTools.variable_map(model)
    h = QUBOTools.linear_terms(model)
    J = QUBOTools.quadratic_terms(model)
    α = QUBOTools.scale(model)
    β = QUBOTools.offset(model)

    return (s, h, J, α, β)
end

function ising(::Type{<:Array}, model::AbstractQUBOModel{<:SpinDomain})
    s = QUBOTools.variable_map(model)
    n = length(s)
    h = zeros(Float64, n)
    J = zeros(Float64, n, n)
    α = QUBOTools.scale(model)
    β = QUBOTools.offset(model)

    for (i, hᵢ) in QUBOTools.linear_terms(model)
        h[i] = hᵢ
    end

    for ((i, j), Jᵢⱼ) in QUBOTools.quadratic_terms(model)
        J[i, j] = Jᵢⱼ
    end

    return (s, h, J, α, β)
end

@doc raw"""
    energy(state::Any, model::AbstractQUBOModel)

This function aims to evaluate the energy of a given state under some QUBO Model.
Scale and offset factors **are assumed** to be taken into account.
""" function energy end

function energy(state, model)
    energy(state, QUBOTools.backend(model))
end

# ~*~ Sizes & Dimensions ~*~ #
@doc raw"""
""" function domain_size end

function domain_size(model::Any)
    length(QUBOTools.variable_map(model))
end

@doc raw"""
""" function linear_size end

function linear_size(model::Any)
    length(QUBOTools.linear_terms(model))
end

@doc raw"""
""" function quadratic_size end

function quadratic_size(model::Any)
    length(QUBOTools.quadratic_terms(model))
end

@doc raw"""
""" function density end

function density(model::Any)
    n = QUBOTools.domain_size(model)
    if n == 0
        return 0.0
    else
        l = QUBOTools.linear_size(model)
        q = QUBOTools.quadratic_size(model)
        return (2 * q + l) / (n * n)
    end
end

@doc raw"""
""" function linear_density end

function linear_density(model::Any)
    n = QUBOTools.domain_size(model)

    if n == 0
        return 0.0
    else
        l = QUBOTools.linear_size(model)
        return l / n
    end
end

@doc raw"""
""" function quadratic_density end

function quadratic_density(model::Any)
    n = QUBOTools.domain_size(model)

    if n <= 1
        return 0.0
    else
        q = QUBOTools.quadratic_size(model)
        return (2 * q) / (n * (n - 1))
    end
end