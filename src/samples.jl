struct Sample{U<:Integer,T<:Number}
    state::Vector{U}
    reads::Int
    value::T

    function Sample{U,T}(state::Vector{U}, reads::Integer, value::T) where {U,T}
        new{U,T}(state, reads, value)
    end

    function Sample{U,T}(sample::Tuple{Vector{<:U},Integer,T}) where {U,T}
        new{U,T}(sample...)
    end
end

function Base.:(==)(x::Sample, y::Sample)
    (x.value == y.value) && (x.reads == y.reads) && (x.state == y.state)
end

struct SampleSet{U,T}
    samples::Vector{Sample{U,T}}

    function SampleSet{U,T}(data::Vector{Sample{U,T}}) where {U,T}
        samples = Sample{U,T}[]
        mapping = Dict{Vector{U},Int}()

        sizehint!(samples, length(data))
        sizehint!(mapping, length(data))

        n = 0

        for sample in data
            if haskey(mapping, sample.state)
                i = mapping[sample.state]
                samples[i] = Sample{U, T}(
                    sample.state,
                    sample.reads + samples[i].reads,
                    sample.value,
                )
            else
                push!(samples, sample)
                mapping[sample.state] = (n += 1)
            end
        end

        sort!(samples; by=(ξ) -> (ξ.value, -ξ.reads, ξ.state))

        new{U,T}(samples)
    end
end

function Base.:(==)(x::SampleSet, y::SampleSet)
    x.samples == y.samples
end

function Base.isempty(s::SampleSet)
    isempty(s.samples)
end

function Base.empty!(set::SampleSet)
    empty!(set.samples)
    empty!(set.mapping)
end

function Base.length(set::SampleSet)
    length(set.samples)
end

function Base.iterate(set::SampleSet)
    iterate(set.samples)
end

function Base.iterate(set::SampleSet, i::Int)
    iterate(set.samples, i)
end

function Base.getindex(set::SampleSet, i::Int)
    getindex(set.samples, i)
end

function Base.merge(setx::SampleSet{U,T}, sety::SampleSet{U,T}) where {U,T}
    SampleSet{U,T}(Sample{U,T}[setx.samples; sety.samples])
end