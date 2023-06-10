@doc raw"""
    AbstractModel{V,T,U}

Represents an abstract QUBO Model and should support most of the queries made available
by `QUBOTools`.
```

As shown in the example above, implementing a method for the [`backend`](@ref) function
gives access to most fallback implementations.
"""
abstract type AbstractModel{V,T,U} end

@doc raw"""
    backend(model)::AbstractModel
    backend(model::AbstractModel)::AbstractModel

Retrieves the model's backend.
Implementing this function allows one to profit from fallback implementations of the other methods.
"""
function backend end

# Data access
@doc raw"""
    name(model)::Union{String,Nothing}

Returns a string for the model's name, or nothing.
"""
function name end

@enum Domain begin
    SpinDomain
    BoolDomain
end

Base.Broadcast.broadcastable(X::Domain) = Ref(X)

@doc raw"""
    BoolDomain <: Domain

```math
x \in \mathbb{B} = \lbrace{0, 1}\rbrace
```
"""
const 𝔹 = BoolDomain

@doc raw"""
    SpinDomain <: Domain

```math
s \in \mathbb{S} = \lbrace{-1, 1}\rbrace
```
"""
const 𝕊 = SpinDomain

@doc raw"""
    domain(model::AbstractModel)::Domain
    domain(fmt::AbstractFormat)::Domain

Returns the singleton representing the variable domain of a given model.
"""
function domain end

@doc raw"""
    scale(model)

"""
function scale end

@doc raw"""
    offset(model)

"""
function offset end

@enum Sense begin
    Min
    Max
end

Base.Broadcast.broadcastable(s::Sense) = Ref(s)

@doc raw"""
    sense(model)::Sense

"""
function sense end

@doc raw"""
    id(model)::Union{Int,Nothing}
"""
function id end

@doc raw"""
    version(model)::Union{VersionNumber,Nothing}
"""
function version end

@doc raw"""
    description(model)::Union{String,Nothing}
"""
function description end

@doc raw"""
    metadata(model)
    metadata(sampleset::SampleSet)
"""
function metadata end

@doc raw"""
    linear_terms(model)::Dict{Int,T} where {T <: Real}

Retrieves the linear terms of a model as a dict.

!!! info
    The `explicit_linear_terms` method includes all variables, breaking linear sparsity.
"""
function linear_terms end

@doc raw"""
    explicit_linear_terms(model)::Dict{Int,T} where {T <: Real}

Retrieves the linear terms of a model as a dict, including zero entries.
"""
function explicit_linear_terms end

@doc raw"""
    quadratic_terms(model)::Dict{Tuple{Int,Int},T} where {T <: Real}

Retrieves the quadratic terms of a model as a dict.
For every key pair ``(i, j)`` holds that ``i < j``.
"""
function quadratic_terms end

@doc raw"""
    indices(model)::Vector{Int}

Returns a sorted vector that matches the variable indices.
It is equivalent to `variable_map.(model, variables(model))`
"""
function indices end

@doc raw"""
    variables(model)::Vector
    variables(model::AbstractModel{V})::Vector{V} where {V}

Returns a sorted vector containing the model's variables.
If order doesn't matter, use [`variable_set`](@ref) instead.
"""
function variables end

@doc raw"""
    variable_set(model)::Set
    variable_set(model::AbstractModel{V})::Set{V} where {V}

Returns the set of variables of a given model.
"""
function variable_set end

@doc raw"""
    variable_map(model::AbstractModel{V})::Dict{V,Int} where {V}

Returns a dictionary that maps variables into their integer indices.

    variable_map(model::AbstractModel{V}, x::V)::Int where {V}

Returns the index of a given variable.
"""
function variable_map end

@doc raw"""
    variable_inv(model::AbstractModel{V})::Vector{V} where {V}

Returns a vector that maps indices into their corresponding variables.

    variable_inv(model::AbstractModel{V}, i::Integer)::V where {V}

Given an index, returns the corresponding varaible.
"""
function variable_inv end

# Model's Normal Forms
@doc raw"""
    form(model::AbstractModel; domain)
    form(model::AbstractModel{_,T}, ::Type{F}; domain) where {_,T,X,F<:AbstractForm{X}}
    form(model)
"""
function form end

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
"""
function qubo end

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

    ising(Q::Dict{Tuple{Int, Int}, T}, α::T = one(T), β::T = zero(T)) where {T}    
    ising(L::Vector{T}, Q::Vector{T}, u::Vector{Int}, v::Vector{Int}, α::T = one(T), β::T = zero(T)) where {T}
    ising(Q::Matrix{T}, α::T = one(T), β::T = zero(T)) where {T}
    ising(Q::SparseMatrixCSC{T}, α::T = one(T), β::T = zero(T)) where {T}

# Ising Normal Form

!!! info
    Apart from the sparse matricial case, the linear terms are explicitly included,
    breaking sparsity by containing zero entries.
"""
function ising end

@doc raw"""
    start(model::AbstractModel{V,T,U}; domain = domain(model))::Dict{Int,U} where {V,T,U}

Returns a dictionary containing a warm-start value for each variable index.
"""
function start end

# Queries: sizes & density
@doc raw"""
    dimension(model)::Integer

Counts the number of variables in the model.
"""
function dimension end

@doc raw"""
    linear_size(model)::Int

Counts the number of non-zero linear terms in the model.
"""
function linear_size end

@doc raw"""
    quadratic_size(model)::Int

Counts the number of non-zero quadratic terms in the model.
"""
function quadratic_size end

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

    adjacency(arch)::Dict{Int,Set{Int}}
    adjacency(device)::Dict{Int,Set{Int}}

!!! warning
    Computing specific neighborhoods is expensive.
    Thus, it is recommended that one stores the adjacency list for repeated access.
"""
function adjacency end

@doc raw"""
    read_model(::AbstractString)
    read_model(::AbstractString, ::AbstractFormat)
"""
function read_model end

 @doc raw"""
    write_model(::AbstractString, ::AbstractModel)
    write_model(::AbstractString, ::AbstractModel, ::AbstractFormat)
    write_model(::IO, ::AbstractModel, ::AbstractFormat)
"""
function write_model end