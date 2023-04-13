cast(::Pair{D,D}, x::Integer) where {D<:Domain} = x
cast(::Pair{BoolDomain,SpinDomain}, x::Integer) = (2 * x) - 1
cast(::Pair{SpinDomain,BoolDomain}, s::Integer) = (s + 1) ÷ 2

cast(::Pair{D,D}, ψ::Vector{U}) where {U<:Integer,D<:Domain}         = copy(ψ)
cast(::Pair{BoolDomain,SpinDomain}, ψ::Vector{U}) where {U<:Integer} = (2 .* ψ) .- 1
cast(::Pair{SpinDomain,BoolDomain}, ψ::Vector{U}) where {U<:Integer} = (ψ .+ 1) .÷ 2

function cast(route::Pair{X,Y}, Ψ::Vector{Vector{U}}) where {U<:Integer,X<:Domain,Y<:Domain}
    return cast.(route, Ψ)
end

@doc raw"""
    Sample{T,U}(state::Vector{U}, value::T, reads::Integer) where{T,U}

""" struct Sample{T<:Real,U<:Integer} <: AbstractVector{U}
    state::Vector{U}
    value::T
    reads::Int

    function Sample{T,U}(state::Vector{U}, value::T, reads::Integer = 1) where {T,U}
        return new{T,U}(state, value, reads)
    end
end

Sample{T}(args...) where {T} = Sample{T,Int}(args...)
Sample(args...)              = Sample{Float64}(args...)

state(s::Sample) = s.state
state(s::Sample, i::Integer) = s.state[i]
value(s::Sample) = s.value
reads(s::Sample) = s.reads

Base.:(==)(u::Sample{T,U}, v::Sample{T,U}) where {T,U} = state(u) == state(v)
Base.:(<)(u::Sample{T,U}, v::Sample{T,U}) where {T,U}  = value(u) < value(v)

function Base.isequal(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return isequal(reads(u), reads(v)) &&
           isequal(value(u), value(v)) &&
           isequal(state(u), state(v))
end

function Base.isless(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    if isequal(value(u), value(v))
        return isless(state(u), state(v))
    else
        return isless(value(u), value(v))
    end
end

Base.print(io::IO, s::Sample)        = join(io, ifelse.(state(s) .> 0, '↓', '↑'))
Base.length(s::Sample)               = length(state(s))
Base.size(s::Sample)                 = (length(s),)
Base.getindex(s::Sample, i::Integer) = state(s, i)
Base.collect(s::Sample)              = collect(state(s))

@doc raw"""
    merge(u::Sample{T,U}, v::Sample{T,U}) where {T,U}

Assumes that `u == v`.
"""
function Base.merge(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return Sample{T,U}(state(u), value(u), reads(u) + reads(v))
end

function format(data::Vector{Sample{T,U}}) where {T,U}
    bits  = nothing
    cache = sizehint!(Dict{Vector{U},Sample{T,U}}(), length(data))

    for sample::Sample{T,U} in data
        cached = get(cache, state(sample), nothing)
        merged = if isnothing(cached)
            if isnothing(bits)
                bits = length(sample)
            elseif bits != length(sample)
                sampling_error("All samples must have states of equal length")
            end

            sample
        else
            if value(cached) != value(sample)
                sampling_error(
                    "Samples of the same state vector must have the same energy value",
                )
            end

            merge(cached, sample)
        end

        cache[state(merged)] = merged
    end

    return sort(collect(values(cache)))
end

function cast(route::Pair{X,Y}, s::Sample{T,U}) where {T,U,X<:Domain,Y<:Domain}
    return Sample{T,U}(cast(route, state(s)), value(s), reads(s))
end

function cast(::Pair{S,S}, s::Sample{T,U}) where {S<:Sense,T,U}
    return Sample{T,U}(state(s), value(s), reads(s))
end

function cast(::Pair{A,B}, s::Sample{T,U}) where {T,U,A<:Sense,B<:Sense}
    return Sample{T,U}(state(s), -value(s), reads(s))
end

@doc raw"""
    AbstractSampleSet{T<:real,U<:Integer}

An abstract sampleset is, by definition, an ordered set of samples.
""" abstract type AbstractSampleSet{T<:Real,U<:Integer} <: AbstractVector{T} end

Base.size(ω::AbstractSampleSet) = (size(ω, 1),)

function Base.size(ω::AbstractSampleSet, axis::Integer)
    if axis == 1
        return length(ω)
    else
        return 1
    end
end

Base.firstindex(::AbstractSampleSet)            = 1
Base.firstindex(::AbstractSampleSet, ::Integer) = 1
Base.lastindex(ω::AbstractSampleSet)            = length(ω)

function Base.lastindex(ω::AbstractSampleSet, axis::Integer)
    if axis == 1
        return length(ω)
    elseif axis == 2 && !isempty(ω)
        return length(ω[begin])
    else
        return 1
    end
end

Base.iterate(ω::AbstractSampleSet) = iterate(ω, firstindex(ω))

function Base.iterate(ω::AbstractSampleSet, i::Integer)
    if 1 <= i <= length(ω)
        return (getindex(ω, i), i + 1)
    else
        return nothing
    end
end

function Base.show(io::IO, ω::S) where {S<:AbstractSampleSet}
    if isempty(ω)
        return println(io, "Empty $(S)")
    end

    println(io, "$(S) with $(length(ω)) samples:")

    for (i, s) in enumerate(ω)
        print(io, "  ")

        if i < 10
            println(io, s)
        else
            return println(io, "⋮")
        end
    end

    return nothing
end

# ~*~ :: Metadata Validation :: ~*~ #
const _SAMPLESET_METADATA_PATH   = joinpath(@__DIR__, "sampleset.schema.json")
const _SAMPLESET_METADATA_DATA   = JSON.parsefile(_SAMPLESET_METADATA_PATH)
const _SAMPLESET_METADATA_SCHEMA = JSONSchema.Schema(_SAMPLESET_METADATA_DATA)

function validate(ω::AbstractSampleSet)
    report = JSONSchema.validate(_SAMPLESET_METADATA_SCHEMA, metadata(ω))

    if !isnothing(report)
        @warn report
        return false
    else
        return true
    end
end

state(ω::AbstractSampleSet, i::Integer)             = state(ω[i])
state(ω::AbstractSampleSet, i::Integer, j::Integer) = state(ω[i], j)
value(ω::AbstractSampleSet, i::Integer)             = value(ω[i])
reads(ω::AbstractSampleSet, i::Integer)             = reads(ω[i])
reads(ω::AbstractSampleSet)                         = sum(reads.(ω))

@doc raw"""
    SampleSet{T,U}(
        data::Vector{Sample{T,U}},
        metadata::Dict{String,Any},
    ) where {T,U}

It compresses repeated states by adding up the `reads` field.
It was inspired by [^dwave], with a few tweaks.

!!! info
    A `SampleSet{T,U}` was designed to be read-only.
    It is optimized to support queries over the solution set.

## References
[^dwave]:
    [ocean docs](https://docs.ocean.dwavesys.com/en/stable/docs_dimod/reference/S.html#dimod.SampleSet)
""" struct SampleSet{T,U} <: AbstractSampleSet{T,U}
    data::Vector{Sample{T,U}}
    metadata::Dict{String,Any}

    function SampleSet{T,U}(
        data::Vector{Sample{T,U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {T,U}
        data = format(data)

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(data, metadata)
    end

    function SampleSet{T,U}(metadata::Dict{String,Any}) where {T,U}
        return new{T,U}(Sample{T,U}[], metadata)
    end

    function SampleSet{T,U}() where {T,U}
        return new{T,U}(Sample{T,U}[], Dict{String,Any}())
    end
end

function SampleSet{T,U}(
    model::Any,
    Ψ::Vector{Vector{U}},
    metadata::Union{Dict{String,Any},Nothing} = nothing,
) where {T,U}
    data = Vector{Sample{T,U}}(undef, length(Ψ))

    for i in eachindex(data)
        ψ = Ψ[i]
        λ = value(model, ψ)

        data[i] = Sample{T,U}(ψ, λ)
    end

    return SampleSet{T,U}(data, metadata)
end

SampleSet{T}(args...; kws...) where {T}  = SampleSet{T,Int}(args...; kws...)
SampleSet(args...; kws...)               = SampleSet{Float64}(args...; kws...)
Base.copy(ω::SampleSet{T,U}) where {T,U} = SampleSet{T,U}(copy(ω.data), deepcopy(ω.metadata))

function Base.copy!(ω::SampleSet{T,U}, η::SampleSet{T,U}) where {T,U}
    copy!(ω.data, η.data)
    copy!(ω.metadata, deepcopy(η.metadata))

    return ω
end

Base.:(==)(ω::SampleSet{T,U}, η::SampleSet{T,U}) where {T,U} = (ω.data == η.data)

Base.length(ω::SampleSet)  = length(ω.data)
Base.empty!(ω::SampleSet)  = empty!(ω.data)
Base.isempty(ω::SampleSet) = isempty(ω.data)

Base.collect(ω::SampleSet)              = collect(ω.data)
Base.getindex(ω::SampleSet, i::Integer) = ω.data[i]

Base.iterate(ω::SampleSet)             = iterate(ω.data)
Base.iterate(ω::SampleSet, i::Integer) = iterate(ω.data, i)

metadata(ω::SampleSet) = ω.metadata

function cast(route::Pair{A,B}, ω::SampleSet{T,U}) where {T,U,A<:Sense,B<:Sense}
    return SampleSet{T,U}(Vector{Sample{T,U}}(cast.(route, ω)), deepcopy(metadata(ω)))
end

function cast(route::Pair{X,Y}, ω::SampleSet{T,U}) where {T,U,X<:Domain,Y<:Domain}
    return SampleSet{T,U}(Vector{Sample{T,U}}(cast.(route, ω)), deepcopy(metadata(ω)))
end
