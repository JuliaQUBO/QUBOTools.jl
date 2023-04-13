""" /src/interface/data.jl @ QUBOTools.jl

    This file contains iterfaces for data access within QUBO's format system.
"""

@doc raw"""
    AbstractModel{V,T}

Represents an abstract QUBO Model and should support most of the queries made available
by `QUBOTools`.
```

As shown in the example above, implementing a method for the [`backend`](@ref) function
gives access to most fallback implementations.
""" abstract type AbstractModel{V,T} end

@doc raw"""
    AbstractFormat

""" abstract type AbstractFormat end

@doc raw"""
    Style

""" abstract type Style end

@doc raw"""
    style(::AbstractFormat)::Style
""" function style end

@doc raw"""
    supports_style(::AbstractFormat)::Bool
""" function supports_style end

@doc raw"""
    formats()

Returns a list containing all available QUBO file formats.
""" function formats end

@doc raw"""
    infer_format(::AbstractString)::AbstractFormat
    infer_format(::Symbol)::AbstractFormat
    infer_format(::Symbol, ::Symbol)::AbstractFormat

Given a file path, tries to infer the type associated to a QUBO model format.
""" function infer_format end

@doc raw"""
    backend(model)::AbstractModel
    backend(model::AbstractModel)::AbstractModel

Retrieves the model's backend.
Implementing this function allows one to profit from fallback implementations of the other methods.
""" function backend end

# ~*~ Data access ~*~ #
@doc raw"""
    model_name(model)::String

Returns a string representing the model type.
""" function model_name end

@doc raw"""
    Domain

""" abstract type Domain end

@doc raw"""
    domain(model::AbstractModel)::Domain
    domain(fmt::AbstractFormat)::Domain

Returns the singleton representing the variable domain of a given model.
""" function domain end

@doc raw"""
    supports_domain(::Type{<:AbstractFormat}, ::Domain)
""" function supports_domain end

@doc raw"""
    domains()

Returns the list of available known variable domains.
""" function domains end

@doc raw"""
    scale(model)

""" function scale end

@doc raw"""
    offset(model)

""" function offset end

@doc raw"""
    Sense

""" abstract type Sense end

@doc raw"""
    sense(model)::Sense

""" function sense end

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
    metadata(model::AbstractModel)
    metadata(sampleset::SampleSet)
""" function metadata end

@doc raw"""
    sampleset(model)::SampleSet

Returns the [`SampleSet`](@ref) stored in a model.
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
    indices(model)::Vector{Int}

Returns a sorted vector that matches the variable indices.
It is equivalent to `variable_map.(model, variables(model))`
""" function indices end

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
    qubo(model::AbstractModel{<:BoolDomain})
    qubo(model::AbstractModel{<:BoolDomain}, ::Type{Dict}, T::Type = Float64)

Returns sparse dictionary representation.

    qubo(model::AbstractModel{<:BoolDomain}, ::Type{Vector}, T::Type = Float64)

Returns sparse vector quadruple (linear, quadratic, lower index & upper index).

    qubo(model::AbstractModel{<:BoolDomain}, ::Type{Matrix}, T::Type = Float64)

Returns dense matrix representation.

    qubo(model::AbstractModel{<:BoolDomain}, ::Type{SparseMatrixCSC}, T::Type = Float64)

Returns sparse matrix representation.

    qubo(model::AbstractModel{<:SpinDomain}, args...)

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
    ising(model::AbstractModel{<:SpinDomain})
    ising(model::AbstractModel{<:SpinDomain}, ::Type{<:Dict}, T::Type = Float64))

Returns sparce dictionary representation

    ising(model::AbstractModel{<:BoolDomain}, ::Type{Vector}, T::Type = Float64)

Returns sparse vector quadruple (linear, quadratic, lower index & upper index).

    ising(model::AbstractModel{<:BoolDomain}, ::Type{Matrix}, T::Type = Float64)

Returns dense matrix representation.

    ising(model::AbstractModel{<:SpinDomain}, ::Type{SparseMatrixCSC}, T::Type = Float64)

Returns sparce matrix representation

    ising(model::AbstractModel{<:BoolDomain}, args...)

Returns Ising Model form from QUBO Model (Bool).

    ising(h::Dict{Int,T}, J::Dict{Tuple{Int, Int}, T}, α::T = one(T), β::T = zero(T)) where {T}    
    ising(h::Vector{T}, J::Vector{T}, u::Vector{Int}, v::Vector{Int}, α::T = one(T), β::T = zero(T)) where {T}
    ising(h::Vector{T}, J::Matrix{T}, α::T = one(T), β::T = zero(T)) where {T}
    ising(h::SparseVector{T}, J::SparseMatrixCSC{T}, α::T = one(T), β::T = zero(T)) where {T}

# Ising Normal Form

!!! info
    Apart from the sparse matricial case, the linear terms are explicitly included,
    breaking sparsity by containing zero entries.
""" function ising end

# ~*~ Data queries ~*~ #
@doc raw"""
    state(model, i::Integer)

Returns the state vector corresponding to the ``i``-th solution on the model's sampleset.
""" function state end

@doc raw"""
    reads(model)
    reads(model, i::Integer)

Returns the read frequency of the ``i``-th solution on the model's sampleset.
""" function reads end

@doc raw"""
    value(model, state::Vector)
    value(model, index::Integer)

This function aims to evaluate the energy of a given state under some QUBO Model.

    value(Q::Dict{Tuple{Int,Int},T}, ψ::Vector{U}, α::T = one(T), β::T = zero(T)) where {T}
    value(h::Dict{Int,T}, J::Dict{Tuple{Int,Int},T}, ψ::Vector{U}, α::T = one(T), β::T = zero(T)) where {T}


!!! info
    Scale and offset factors are taken into account.
""" function value end

@doc raw"""
    energy

An alias for [`value`](@ref).
""" const energy = value

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
    adjacency(G::Vector{Tuple{Int,Int}})::Dict{Int,Set{Int}}
    adjacency(G::Set{Tuple{Int,Int}})::Dict{Int,Set{Int}}
    adjacency(G::Dict{Tuple{Int,Int},T})::Dict{Int,Set{Int}}

Computes the adjacency list representation for the quadratic terms of a given model.
A mapping between each variable index and the set of its neighbors is returned.

    adjacency(model, k::Integer)::Set{Int}
    adjacency(G::Vector{Tuple{Int,Int}}, k::Integer)::Set{Int}
    adjacency(G::Set{Tuple{Int,Int}}, k::Integer)::Set{Int}
    adjacency(G::Dict{Tuple{Int,Int},T}, k::Integer)::Set{Int}

If a second parameter, an integer, is present, then the set of neighbors of that node is returned.

!!! warning
    Computing specific neighborhoods is expensive.
    Thus, it is recommended that one stores the adjacency list for repeated access.
""" function adjacency end

@doc raw"""
    validate(model)::Bool
    validate(ω::AbstractSampleSet)::Bool

""" function validate end

@doc raw"""
    format(data::Vector{Sample{T,U}}) where {T,U}
""" function format end

@doc raw"""
    cast(
        sense_route::Pair{A,B},
        domain_route::Pair{X,Y},
        data,
    ) where {A<:Sense,B<:Sense,X<:Domain,Y<:Domain}

    cast(::S, ::S, model::AbstractModel) where {S<:Sense}
    cast(::A, ::B, model::AbstractModel) where {A<:Sense,B<:Sense}

Recasting the sense of a model preserves its meaning:

```math
\begin{array}{ll}
    \min_{s} \alpha [f(s) + \beta] &\equiv \max_{s} -\alpha [f(s) + \beta] \\
                                   &\equiv \max_{s} \alpha [-f(s) - \beta] \\
\end{array}
```

The linear terms, quadratic terms and constant offset of a model have its signs reversed.

    cast(::S, ::S, s::Sample) where {S<:Sense}
    cast(::A, ::B, s::Sample) where {A<:Sense,B<:Sense}
    cast(::S, ::S, ω::SampleSet) where {S<:Sense}
    cast(::A, ::B, ω::SampleSet) where {A<:Sense,B<:Sense}

    cast(target, model::AbstractModel)
    cast(route, ψ::Vector{U})
    cast(route, Ψ::Vector{Vector{U}})
    cast(route, ω::SampleSet)

Returns a new object, switching its domain from `source` to `target`.

Reverses the sign of the objective value.
""" function cast end

@doc raw"""
    read_model(::AbstractString)
    read_model(::AbstractString, ::AbstractFormat)
""" function read_model end

@doc raw"""
    read_model!(::AbstractModel, ::AbstractString)
""" function read_model! end

@doc raw"""
    supports_read(::Type{F}) where {F<:AbstractFormat}
 """ function supports_read end

 @doc raw"""
    write_model(::AbstractString, ::AbstractModel)
    write_model(::AbstractString, ::AbstractModel, ::AbstractFormat)
    write_model(::IO, ::AbstractModel, ::AbstractFormat)

""" function write_model end

@doc raw"""
    supports_read(::Type{F}) where {F<:AbstractFormat}

""" function supports_write end