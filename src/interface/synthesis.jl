@doc raw"""
    AbstractProType{T}
"""
abstract type AbstractProblem{T} end

@doc raw"""
    generate(problem)
    generate(rng, problem)

Generates a QUBO problem and returns it as a [`Model`](@ref).
"""
function generate end
