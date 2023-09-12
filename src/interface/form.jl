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
    form(model::Any)::F where {T,F<:AbstractForm{T}}

Returns the QUBO form stored within a model.
"""
function form end

@doc raw"""
    formtype(spec::Any)

Returns a form type according to the given specification.
"""
function formtype end


abstract type AbstractLinearForm{T} end

@doc raw"""
    linear_form(Φ::F) where {T,F<:AbstractForm{T}}

Returns the linear part of the QUBO form.
"""
function linear_form end


abstract type AbstractQuadraticForm{T} end

@doc raw"""
    quadratic_form(Φ::F) where {T,F<:AbstractForm{T}}

Returns the quadratic part of the QUBO form.
"""
function quadratic_form end



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
