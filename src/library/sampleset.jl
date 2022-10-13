@doc raw"""
""" struct Sample{T<:Real,U<:Integer}
    state::Vector{U}
    reads::Int
    value::T

    function Sample{T,U}(state::Vector{U}, reads::Int, value::T) where {T,U}
        return new{T,U}(state, reads, value)
    end

    Sample{T}(args...) where {T} = Sample{T,Int}(args...)
    Sample(args...) = Sample{Float64,Int}(args...)
end

function Base.:(==)(x::Sample{T,U}, y::Sample{T,U}) where {T,U}
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
""" struct SampleSet{T<:Real,U<:Integer}
    reads::Int
    samples::Vector{Sample{T,U}}
    metadata::Dict{String,Any}

    # ~ Empty SampleSet ~ #
    function SampleSet{T,U}() where {T,U}
        new{T,U}(0, Sample{T,U}[], Dict{String,Any}())
    end

    # ~ Default Constructor ~ #
    function SampleSet{T,U}(
        data::Vector{Sample{T,U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {T,U}
        # ~*~ Compress samples ~*~
        bits    = nothing
        reads   = 0
        mapping = Dict{Vector{U},Sample{T,U}}()

        for sample::Sample{T,U} in data
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
                    Sample{T,U}(sample.state, sample.reads + cached.reads, sample.value)
            end

            reads += sample.reads
        end

        samples =
            sort(collect(values(mapping)); by = (sample) -> (sample.value, -sample.reads))

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(reads, samples, metadata)
    end

    function SampleSet{T,U}(
        model,
        data::Vector{Vector{U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {T,U}
        return SampleSet{T,U}(
            Sample{T,U}[
                Sample{T,U}(state, 1, QUBOTools.energy(model, state)) for state in data
            ],
            metadata,
        )
    end

    SampleSet{T}(args...) where {T} = SampleSet{T,Int}(args...)
    SampleSet(args...) = SampleSet{Float64,Int}(args...)
end

function Base.copy(sampleset::SampleSet{T,U}) where {T,U}
    SampleSet{T,U}(copy(sampleset.samples), deepcopy(sampleset.metadata))
end

function Base.length(sampleset::SampleSet)
    return length(sampleset.samples)
end

function Base.:(==)(sampleset::SampleSet{T,U}, Y::SampleSet{T,U}) where {T,U}
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

const SAMPLESET_METADATA_SCHEMA =
    JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "sampleset.schema.json")))

# function Base.isvalid(sampleset::SampleSet)
#     report = JSONSchema.validate(SAMPLESET_METADATA_SCHEMA, sampleset.metadata)

#     if !isnothing(report)
#         @warn report
#         return false
#     else
#         return true
#     end
# end