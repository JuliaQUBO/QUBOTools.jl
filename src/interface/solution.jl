@doc raw"""
    AbstractSolution{T,U}
"""
abstract type AbstractSolution{T,U} end

@doc raw"""
    AbstractSample{T,U}
"""
abstract type AbstractSample{T,U} end

@doc raw"""
    sampleset(model)::SampleSet

Returns the [`SampleSet`](@ref) stored in a model.
"""
function sampleset end

@doc raw"""
    solution(model)::AbstractSolution{T,U} where {T,U}
"""
function solution end

@doc raw"""
    sample(model)::AbstractSolution{T,U} where {T,U}
"""
function sample end

@doc raw"""
    state(model, i::Integer)

Returns the state vector corresponding to the ``i``-th solution on the model's sampleset.
"""
function state end

@doc raw"""
    reads(model)
    reads(model, i::Integer)

Returns the read frequency of the ``i``-th solution on the model's sampleset.
"""
function reads end

@doc raw"""
    value(model, state::Vector{U}) where {U<:Integer}
    value(model, index::Integer)

This function aims to evaluate the energy of a given state under some QUBO Model.

    value(Q::Dict{Tuple{Int,Int},T}, ψ::Vector{U}, α::T = one(T), β::T = zero(T)) where {T}
    value(h::Dict{Int,T}, J::Dict{Tuple{Int,Int},T}, ψ::Vector{U}, α::T = one(T), β::T = zero(T)) where {T}


!!! info
    Scale and offset factors are taken into account.
"""
function value end

@doc raw"""
    energy

An alias for [`value`](@ref).
"""
const energy = value