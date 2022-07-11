@doc raw"""
""" struct Sample{U<:Integer, T<:Real}
    state::Vector{U}
    reads::Int
    value::T
end

function Base.:(==)(x::Sample{U, T}, y::Sample{U, T}) where {U, T}
    x.value == y.value &&
    x.reads == y.reads &&
    x.state == y.state
end

@doc raw"""
    SampleSet{U, T}(
        samples::Vector{Sample{U, T}},
        metadata::Dict{String, Any},
    ) where {U, T}

The SampleSet is intended to be read-only.
It compresses repeated states by adding up the `reads` field.
It was clearly inspired by [1], with a few tweaks.

## Ideas
1. Build Plot Recipes for this type in order to generate sampling barplots.
2. Export to compressed ASCII JSON format.

## References
[1] https://docs.ocean.dwavesys.com/en/stable/docs_dimod/reference/sampleset.html#dimod.SampleSet
""" struct SampleSet{U<:Integer, T<:Real}
    samples::Vector{Sample{U, T}}
    metadata::Dict{String, Any}

    function SampleSet{U, T}(
            data::Vector{Sample{U, T}},
            metadata::Union{Dict{String, Any}, Nothing} = nothing,
            ) where {U, T}
        # ~*~ Compress samples ~*~
        mapping = Dict{Vector{U}, Sample{U, T}}()

        for sample::Sample{U, T} in data
            cached = get(mapping, sample.state, nothing)

            if isnothing(cached)
                mapping[sample.state] = sample
            else
                @assert cached.state == sample.state
                @assert cached.value == sample.value
            
                mapping[sample.state] = Sample{U, T}(
                    sample.state,
                    sample.reads + cached.reads,
                    sample.value,
                )
            end
        end

        samples = sort(
            collect(values(mapping));
            by=(sample)->(sample.value, -sample.reads),
        )

        if isnothing(metadata)
            metadata = Dict{String, Any}()
        end

        new{U, T}(samples, metadata)
    end

    function SampleSet{U, T}(
            data::Vector{U},
            model::AbstractBQPModel,
            metadata::Union{Dict{String, Any}, Nothing} = nothing,
        ) where {U, T}
        SampleSet{U, T}(
            Sample{U, T}[Sample{U, T}(state, 1, BQPIO.energy(state, model)) for state in data],
            metadata
        )
    end
end

function Base.copy(sampleset::SampleSet{U, T}) where {U, T}
    SampleSet{U, T}(copy(sampleset.samples))
end

function Base.length(X::SampleSet)
    length(X.samples)
end

function Base.:(==)(X::SampleSet{U, T}, Y::SampleSet{U, T}) where {U, T}
    length(X) == length(Y) && all(X.samples .== Y.samples)
end