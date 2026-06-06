@doc raw"""
    State
"""
const State{U<:Integer} = AbstractVector{U}

@doc raw"""
    AbstractSample

A sample is a triple ``(\psi, \lambda, r)`` where ``\psi \in \mathbb{U}^{n} \sim \mathbb{B}^{n}`` is
the sampled vector, ``\lambda \in \mathbb{R}`` is the associated energy value and ``r \in \mathbb{N}``
is the number of reads, i. e., the multiplicity of the sample.
"""
abstract type AbstractSample{T,U<:Integer} end

@doc raw"""
    AbstractSolution

By definitioon, a solution is an ordered set of samples.

See [`QUBOTools.AbstractSample`](@ref).
"""
abstract type AbstractSolution{T,U<:Integer} end

@doc raw"""
    solution(model) where {T,U<:Integer}

Returns the model's current solution.
"""
function solution end

@doc raw"""
    sample(model, i::Integer)

Returns the ``i``-th sample on the model's current solution, if available.
"""
function sample end

@doc raw"""
    hassample(solution::AbstractSolution, i::Integer)

Tells if the ``i``-th sample is available on the solution.
"""
function hassample end

@doc raw"""
    state(sample::AbstractSample{T,U}) where {T,U<:Integer}

Returns a vector containing the assingment of each variable in a sample.

    state(model, i::Integer) where {U<:Integer}

Returns a vector corresponding to the bitstring of the ``i``-th sample on the model's current solution, if available.
"""
function state end

@doc raw"""
    reads(model)
    reads(solution::AbstractSolution)

Returns the total amount of reads from each sample, combined.

    reads(model, i::Integer)
    reads(solution::AbstractSolution, i::Integer)

Returns the sampling frequency of the ``i``-th sample on the model's current solution, if available.
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

@doc raw"""
    objective_breakdown(model_or_form, state; variables = nothing)
    objective_breakdown(model, sample)
    objective_breakdown(model, i::Integer)

Return a structured objective-value breakdown for `state`.

The breakdown separates the raw quadratic value, the scaled value, and the
offset-adjusted value used by [`value`](@ref). When `variables` is provided for
a model and vector state, the vector is interpreted in that variable order and
projected to the model's variable order before evaluation. The `sample` and
integer overloads evaluate state data without a surrounding solution frame, so
the state is assumed to already be in the model domain; use
[`annotate_objectives!`](@ref) or [`verify_objective_values`](@ref) when
evaluating samples from a `SampleSet` whose frame may differ from the model. The
integer overload interprets `i` as the index of a sample in `solution(model)`.
"""
function objective_breakdown end

@doc raw"""
    annotate_objectives!(sampleset, model; label = :objective, variables = nothing)

Compute objective breakdown rows for each sample and store them under
`metadata(sampleset)["objectives"][label]`. Stored rows record the evaluated
state, after any solution-domain cast or variable projection needed to evaluate
against `model`.
"""
function annotate_objectives! end

@doc raw"""
    objective_value_mismatches(model, sampleset; atol = 0, rtol = sqrt(eps(Float64)))

Return detailed records for samples whose stored values do not match model
evaluation within tolerance.
"""
function objective_value_mismatches end

@doc raw"""
    verify_objective_values(model, sampleset; kws...)

Return `true` when every stored sample value matches model evaluation within the
given tolerance.
"""
function verify_objective_values end

@doc raw"""
    read_solution(::AbstractString)
    read_solution(::AbstractString, ::AbstractFormat)
    read_solution(::IO, ::AbstractFormat)
"""
function read_solution end

@doc raw"""
    write_solution(::AbstractString, ::AbstractSolution)
    write_solution(::AbstractString, ::AbstractSolution, ::AbstractFormat)
    write_solution(::IO, ::AbstractSolution, ::AbstractFormat)
"""
function write_solution end
