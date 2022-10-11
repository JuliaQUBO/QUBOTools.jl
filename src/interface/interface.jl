""" /src/interface/data.jl @ QUBOTools.jl

    This file contains iterfaces for data access within QUBO's format system.
    
    It also contains a few ones for executing queries on models.
"""

@doc raw"""
    backend(model)::AbstractQUBOModel
    backend(model::AbstractQUBOModel)::AbstractQUBOModel

Retrieves the model's backend.
Implementing this function allows one to profit from fallback implementations of the other methods.
""" function backend end

# ~*~ Data access ~*~ #
@doc raw"""
    model_name(model)::String

Returns a string representing the model type.
""" function model_name end

@doc raw"""
    domain(model)::VariableDomain

Returns the type representing the variable domain of a given model.
""" function domain end

@doc raw"""
    domain_name(model)::String

Returns a string representing the variable domain.
""" function domain_name end

@doc raw"""
    swap_domain(source, target, model)
    swap_domain(source, target, state)
    swap_domain(source, target, states)
    swap_domain(source, target, sampleset)

Returns a new object, switching its domain from `source` to `target`.
""" function swap_domain end

@doc raw"""
    offset(model)::T where {T <: Real}

""" function offset end

@doc raw"""
    scale(model)::T where {T <: Real}

""" function scale end

@doc raw"""
    id(model)::Integer
""" function id end

@doc raw"""
    version(model)::Union{VersionNumber, Nothing}
""" function version end

@doc raw"""
    description(model)::Union{String, Nothing}
""" function description end

@doc raw"""
    metadata(model)::Dict{String, Any}
""" function metadata end

@doc raw"""
    sampleset(model)::QUBOTools.SampleSet
""" function sampleset end

@doc raw"""
    linear_terms(model)::Dict{Int,T} where {T <: Real}

Retrieves the linear terms of a model as a dict.

!!! info
    The `explicit_linear_terms` method includes all variables, breaking linear sparsity.
""" function linear_terms end

@doc raw"""
    explicit_linear_terms(model)::Dict{Int,T} where {T <: Real}

Retrieves the linear terms of a model as a dict, including zero entries.
""" function explicit_linear_terms end

@doc raw"""
    quadratic_terms(model)::Dict{Tuple{Int,Int},T} where {T <: Real}

Retrieves the quadratic terms of a model as a dict.
For every key pair ``(i, j)`` holds that ``i < j``.
""" function quadratic_terms end

@doc raw"""
    variables(model)::Vector

Returns a sorted vector containing the model's variables.
If order doesn't matter, use `variable_set(model)` instead.
""" function variables end

@doc raw"""
    variable_set(model)::Set

Returns the set of variables of a given model.
""" function variable_set end

@doc raw"""
    variable_map(model)::Dict{V,Int} where {V}
    variable_map(model, x::V)::Integer where {V}

""" function variable_map end

@doc raw"""
    variable_inv(model)::Dict{Int,V} where {V}
    variable_inv(model, i::Integer)::V where {V}

    """ function variable_inv end

# ~*~ Model's Normal Forms ~*~ #
@doc raw"""
    qubo(model::AbstractQUBOModel{<:BoolDomain})
    qubo(model::AbstractQUBOModel{<:BoolDomain}, ::Type{Dict}, T::Type = Float64)

Returns sparse dictionary representation.

    qubo(model::AbstractQUBOModel{<:BoolDomain}, ::Type{Vector}, T::Type = Float64)

Returns sparse vector quadruple (linear, quadratic, lower index & upper index).

    qubo(model::AbstractQUBOModel{<:BoolDomain}, ::Type{Matrix}, T::Type = Float64)

Returns dense matrix representation.

    qubo(model::AbstractQUBOModel{<:BoolDomain}, ::Type{SparseMatrixCSC}, T::Type = Float64)

Returns sparse matrix representation.

    qubo(model::AbstractQUBOModel{<:SpinDomain}, args...)

Returns QUBO form from Ising Model (Spin).

    qubo(h::Dict{Int,T}, J::Dict{Tuple{Int, Int}, T}, α::T = one(T), β::T = zero(T)) where {T}
    qubo(h::Vector{T}, J::Vector{T}, u::Vector{Int}, v::Vector{Int}, α::T = one(T), β::T = zero(T)) where {T}
    qubo(h::Vector{T}, J::Matrix{T}, α::T = one(T), β::T = zero(T)) where {T}
    qubo(h::SparseVector{T}, J::SparseMatrixCSC{T}, α::T = one(T), β::T = zero(T)) where {T}

!!! info
    Apart from the sparse matricial case, the linear terms are explicitly included,
    breaking sparsity by containing zero entries.
""" function qubo end

@doc raw"""
    ising(model::AbstractQUBOModel{<:SpinDomain})
    ising(::Type{<:Dict}, model::AbstractQUBOModel{<:SpinDomain})
    ising(::Type{<:Array}, model::AbstractQUBOModel{<:SpinDomain})

# Ising Normal Form

```math
H(\mathbf{s}) = \alpha \left[{ \mathbf{s}'\,J\,\mathbf{s} + \mathbf{h}\,\mathbf{s} + \beta }\right]
```

Returns a quadruple ``(h, J, \alpha, \beta)`` where:
* `h::Dict{Int, T}` is a sparse vector for the linear terms of the Ising Model.
* `J::Dict{Tuple{Int, Int}, T}` is a sparse representation of the quadratic magnetic interactions.
* `α::T` is the scaling factor.
* `β::T` is the offset constant.

!!! info
    The main diagonal is explicitly included, breaking sparsity by containing zero entries.
""" function ising end

# ~*~ Data queries ~*~ #
@doc raw"""
    state(model, index)
""" function state end

@doc raw"""
    reads(model)
    reads(model, index)
""" function reads end

@doc raw"""
    energy(model, state::Vector)
    energy(model, index::Integer)

This function aims to evaluate the energy of a given state under some QUBO Model.

!!! info
    Scale and offset factors are taken into account.

    energy(Q::Dict{Tuple{Int,Int},T}, state::Vector)
    energy(h::Dict{Int,T}, J::Dict{Tuple{Int,Int},T}, state::Vector)
""" function energy end

# ~*~ Queries: sizes & density ~*~ #
@doc raw"""
    domain_size(model)::Integer

Counts the number of variables in the model.
""" function domain_size end

@doc raw"""
    linear_size(model)::Int

Counts the number of non-zero linear terms in the model.
""" function linear_size end

@doc raw"""
    quadratic_size(model)::Int

Counts the number of non-zero quadratic terms in the model.
""" function quadratic_size end

@doc raw"""
    density(model)::Float64

Computes the density ``\rho`` of non-zero terms in a model, according to the expression
```math
\rho = \frac{2Q + L}{N^{2}}
```
where ``L`` is the number of non-zero linear terms, ``Q`` the number of quadratic ones and ``N`` the number of variables.

If the model is empty, returns `NaN`.
""" function density end

@doc raw"""
    linear_density(model)::Float64

Computes the linear density ``\rho_{l}``, given by
```math
\rho_{l} = \frac{L}{N}
```
where ``L`` is the number of non-zero linear terms and ``N`` the number of variables.
""" function linear_density end

@doc raw"""
    quadratic_density(model)::Float64

Computes the linear density ``\rho_{q}``, given by
```math
\rho_{q} = \frac{2Q}{N (N - 1)}
```
where ``Q`` is the number of non-zero quadratic terms and ``N`` the number of variables.
""" function quadratic_density end

@doc raw"""
    adjacency(model)::Dict{Int,Set{Int}}
    adjacency(model, i::Integer)::Set{Int}
    adjacency(Q::Dict{Tuple{Int,Int},T})::Dict{Int,Set{Int}}
    adjacency(Q::Dict{Tuple{Int,Int},T}, i::Integer)::Set{Int}

Computes the adjacency list representation for the quadratic terms of a given model.
A mapping between the variable's index and the set of its neighbors is returned.

If a second parameter, an integer, is present, then the set of neighbors of that node is returned.

!!! warning
    Computing specific neighborhoods is expensive.
    Thus, it is recommended that one stores the adjacency list for repeated access.
""" function adjacency end

# ~*~ Internal: bridge validation ~*~ #
@doc raw"""
    _isvalidbridge(source::M, target::M, ::Type{<:AbstractQUBOModel}; kws...) where M <: AbstractQUBOModel

Checks if the `source` model is equivalent to the `target` reference modulo the given origin type.
Key-word arguments `kws...` are passed to interal `isapprox(::T, ::T; kws...)` calls.

""" function _isvalidbridge end