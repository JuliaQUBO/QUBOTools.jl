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
    variable(model::AbstractModel{V}, i::Integer)::V where {V}

Given an index, returns the corresponding variable.
"""
function variable end

@doc raw"""
    variable_set(model)::Set
    variable_set(model::AbstractModel{V})::Set{V} where {V}

Returns the set of variables of a given model.
"""
function variable_set end

@doc raw"""
    index(model::AbstractModel{V}, v::V)::Int where {V}

Given a variable, returns the corresponding index.
"""
function index end

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

Given an index, returns the corresponding varaible, as does [`variable`](@ref).
"""
function variable_inv end

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
    topology(model; tol::T = zero(T)) where {T}

Computes the adjacency matrix representation for the quadratic terms of a given model.

    topology(model, k::Integer; tol::T = zero(T)) where {T}

Computes the adjacency vector representation for the quadratic terms of a given model,
with respect to the variable with index ``k``.
"""
function topology end

@doc raw"""
    adjacency

An alias for [`topology`](@ref).
"""
const adjacency = topology

@doc raw"""
    read_model(::AbstractString)
    read_model(::AbstractString, ::AbstractFormat)
    read_model(::IO, ::AbstractFormat)
"""
function read_model end

@doc raw"""
    write_model(::AbstractString, ::AbstractModel)
    write_model(::AbstractString, ::AbstractModel, ::AbstractFormat)
    write_model(::IO, ::AbstractModel, ::AbstractFormat)
"""
function write_model end

@doc raw"""
    attach!(model::AbstractModel{V,T,U}, sol::AbstractSolution{T,U}) where {V,T,U}

Attaches solution to model, replacing existing data and solution metadata.
"""
function attach! end
