@doc raw"""
""" struct Sample{U<:Integer,T<:Real}
    state::Vector{U}
    reads::Int
    value::T
end

function Base.:(==)(x::Sample{U,T}, y::Sample{U,T}) where {U,T}
    return x.value == y.value && x.reads == y.reads && x.state == y.state
end

function Base.length(x::Sample)
    return length(x.state)
end

function Base.isempty(x::Sample)
    return isempty(x.state) || iszero(x.reads)
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
""" struct SampleSet{U<:Integer,T<:Real}
    reads::Int
    samples::Vector{Sample{U,T}}
    metadata::Dict{String,Any}

    # ~ Empty SampleSet ~ #
    function SampleSet{U,T}() where {U,T}
        new{U,T}(0, Sample{U,T}[], Dict{String,Any}())
    end

    # ~ Default Constructor ~ #
    function SampleSet{U,T}(
        data::Vector{Sample{U,T}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {U,T}
        # ~*~ Compress samples ~*~
        bits    = nothing
        reads   = 0
        mapping = Dict{Vector{U},Sample{U,T}}()

        for sample::Sample{U,T} in data
            cached = get(mapping, sample.state, nothing)

            if isnothing(cached)
                # ~ Verify if all states are the same length
                if isnothing(bits)
                    bits = length(sample.state)
                elseif bits != length(sample.state)
                    sample_error("All samples must have states of equal length")
                end

                mapping[sample.state] = sample
            else
                if !(cached.value ≈ sample.value)
                    sample_error(
                        "Samples of the same state vector must have the same energy value",
                    )
                end

                mapping[sample.state] =
                    Sample{U,T}(sample.state, sample.reads + cached.reads, sample.value)
            end

            reads += sample.reads
        end

        samples =
            sort(collect(values(mapping)); by = (sample) -> (sample.value, -sample.reads))

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{U,T}(reads, samples, metadata)
    end

    function SampleSet{U,T}(
        model,
        data::Vector{Vector{U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {U,T}
        return SampleSet{U,T}(
            Sample{U,T}[
                Sample{U,T}(state, 1, QUBOTools.energy(state, model)) for state in data
            ],
            metadata,
        )
    end
end

function Base.copy(sampleset::SampleSet{U,T}) where {U,T}
    SampleSet{U,T}(copy(sampleset.samples), deepcopy(sampleset.metadata))
end

function Base.length(sampleset::SampleSet)
    return length(sampleset.samples)
end

function Base.:(==)(sampleset::SampleSet{U,T}, Y::SampleSet{U,T}) where {U,T}
    return length(sampleset) == length(Y) && all(sampleset.samples .== Y.samples)
end

function Base.iterate(sampleset::SampleSet)
    return iterate(sampleset.samples)
end

function Base.iterate(sampleset::SampleSet, i::Integer)
    return iterate(sampleset.samples, i)
end

function Base.getindex(sampleset::SampleSet, i::Integer)
    return sampleset.samples[i]
end

function Base.getindex(sampleset::SampleSet, i::Integer, j::Integer)
    return sampleset.samples[i].state[j]
end

function Base.isempty(sampleset::SampleSet)
    return isempty(sampleset.samples)
end

const SAMPLESET_METADATA_SCHEMA = JSONSchema.Schema(
    JSON.parsefile(joinpath(@__DIR__, "sampleset.schema.json"))
)

function Base.isvalid(sampleset::SampleSet)
    report = JSONSchema.validate(
        SAMPLESET_METADATA_SCHEMA,
        sampleset.metadata
    )
    
    if !isnothing(report)
        @warn report
        return false
    else
        return true
    end
end