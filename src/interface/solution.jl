@doc raw"""
    AbstractSolution{T,U<:Integer}

By definitioon,
"""
abstract type AbstractSolution{T,U<:Integer} end

@doc raw"""
    AbstractSample{T,U<:Integer}
"""
abstract type AbstractSample{T,U<:Integer} end

@doc raw"""
    State{U<:Integer}
"""
const State{U<:Integer} = AbstractVector{U}

@doc raw"""
    solution(model)::AbstractSolution{T,U} where {T,U<:Integer}

Returns the model's current solution.
"""
function solution end

@doc raw"""
    sample(model, i::Integer)::AbstractSample{T,U} where {T,U<:Integer}

Returns the ``i``-th sample on the model's current solution, if available.
"""
function sample end

@doc raw"""
    state(sample::AbstractSample{T,U})::AbstractVector{U} where {T,U<:Integer}

    state(model, i::Integer)::AbstractVector{U} where {U<:Integer}

Returns the state vector corresponding to the ``i``-th sample on the model's current solution, if available.
"""
function state end

@doc raw"""
    reads(model)::Integer
    reads(solution::AbstractSolution)::Integer

Returns the total amount of reads from each sample, combined.

    reads(model, i::Integer)::Integer
    reads(solution::AbstractSolution, i::Integer)::Integer

Returns the read frequency of the ``i``-th sample on the model's current solution, if available.
"""
function reads end

@doc raw"""
    value(model)::T where {T}
    
    value(model, i::Integer)::T where {T}
    value(solution::AbstractSolution{T,U}, i::Integer)::T where {T,U}

    value(model, state::AbstractVector{U}) where {U<:Integer}
    value(solution::AbstractSolution{T,U}, state::AbstractVector{U})::T where {T,U<:Integer}

    value(Q::Dict{Tuple{Int,Int},T}, ψ::Vector{U}, α::T = one(T), β::T = zero(T)) where {T}
    value(h::Dict{Int,T}, J::Dict{Tuple{Int,Int},T}, ψ::Vector{U}, α::T = one(T), β::T = zero(T)) where {T}
"""
function value end

@doc raw"""
    energy

An alias for [`value`](@ref).
"""
const energy = value