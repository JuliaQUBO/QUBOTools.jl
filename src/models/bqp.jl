@doc raw"""

```math
    s (\sum_{i < j} Q_{i, j} x_i x_j + \sum_{i} Q_{i, i} x_i + c)
```

""" mutable struct BQPModel{D, V, U, T} <: Model{D, V, U, T}
    x::Dict{V, Int}
    y::Dict{Int, V}
    s::T
    Q::Dict{Tuple{Int, Int}, T}
    c::T

    solution::SampleSet{U, T}
    metadata::Dict{String, Any}
end

function sample!(model::BQPModel{<:Any, <:Any, U, T}, data::Vector{Vector{U}}) where {U, T}
    samples = Sample{U, T}[]

    for state in data
        push!(samples, Sample{U, T}(
            satate,
            1,
            model.s * sum(
                q * state[i] * state[j]
                for ((i, j), q) in model.Q; init=model.c
            ),
        ))
    end

    model.solution = SampleSet{U, T}(samples)
end