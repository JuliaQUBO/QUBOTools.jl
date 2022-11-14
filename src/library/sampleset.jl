@doc raw"""
    Sample{T,U}(state::Vector{U}, value::T, reads::Integer) where{T,U}

""" struct Sample{T<:Real,U<:Integer}
    state::Vector{U}
    value::T
    reads::Int

    function Sample{T,U}(state::Vector{U}, value::T, reads::Integer = 1) where {T,U}
        return new{T,U}(state, value, reads)
    end
end

Sample{T}(args...) where {T} = Sample{T,Int}(args...)
Sample(args...)              = Sample{Float64}(args...)

Base.:(==)(u::Sample{T,U}, v::Sample{T,U}) where {T,U} = u.state == v.state
Base.:(<)(u::Sample{T,U}, v::Sample{T,U}) where {T,U}  = u.value < v.value

function Base.isequal(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return isequal(u.reads, v.reads) &&
           isequal(u.value, v.value) &&
           isequal(u.state, v.state)
end

function Base.isless(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return isequal(u.value, v.value) ? isless(u.state, v.state) : isless(u.value, v.value)
end

Base.length(x::Sample) = length(x.state)

Base.show(io::IO, s::Sample) = join(io, ifelse.(s.state .> 0, '↓', '↑');)

Base.getindex(s::Sample, i::Integer) = s.state[i]

@doc raw"""
    merge(u::Sample{T,U}, v::Sample{T,U}) where {T,U}

Assumes that `u == v`.
"""
function Base.merge(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return Sample{T,U}(u.state, u.value, u.reads + v.reads)
end

function compress(samples::Vector{Sample{T,U}}) where {T,U}
    bits  = nothing
    cache = sizehint!(Dict{Vector{U},Sample{T,U}}(), length(samples))

    for sample::Sample{T,U} in samples
        cached = get(cache, sample.state, nothing)
        merged = if isnothing(cached)
            if isnothing(bits)
                bits = length(sample)
            elseif bits != length(sample)
                sample_error("All samples must have states of equal length")
            end

            sample
        else
            if cached.value ≉ sample.value
                sample_error("Samples of the same state vector must have the same energy value")
            end

            merge(cached, sample)
        end

        cache[merged.state] = merged
    end

    return collect(values(cache))
end

reads(s::Sample)  = s.reads
state(s::Sample)  = s.state
energy(s::Sample) = s.value

abstract type AbstractSampleSet{T<:Real,U<:Integer} end

Base.size(ω::AbstractSampleSet) = (size(ω, 1), size(ω, 2))

function Base.size(ω::AbstractSampleSet, axis::Integer)
    if axis == 1
        return length(ω)
    elseif axis == 2 && !isempty(ω)
        return length(ω[begin])
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
const SAMPLESET_METADATA_PATH   = joinpath(@__DIR__, "sampleset.schema.json")
const SAMPLESET_METADATA_DATA   = JSON.parsefile(SAMPLESET_METADATA_PATH)
const SAMPLESET_METADATA_SCHEMA = JSONSchema.Schema(SAMPLESET_METADATA_DATA)

function validate(ω::AbstractSampleSet)
    report = JSONSchema.validate(SAMPLESET_METADATA_SCHEMA, metadata(ω))

    if !isnothing(report)
        @warn report
        return false
    else
        return true
    end
end

swap_domain(::D, ::D, ψ::Vector{U}) where {D<:𝔻,U<:Integer}         = ψ
swap_domain(::𝕊, ::𝔹, ψ::Vector{U}) where {U<:Integer}              = (ψ .+ 1) .÷ 2
swap_domain(::𝔹, ::𝕊, ψ::Vector{U}) where {U<:Integer}              = (2 .* ψ) .- 1
swap_domain(::D, ::D, Ψ::Vector{Vector{U}}) where {D<:𝔻,U<:Integer} = Ψ
swap_domain(::D, ::D, ω::AbstractSampleSet{T,U}) where {D<:𝔻,T,U}   = ω

function swap_domain(::A, ::B, Ψ::Vector{Vector{U}}) where {A<:𝔻,B<:𝔻,U<:Integer}
    return swap_domain.(A(), B(), Ψ)
end

function swap_domain(::A, ::B, s::Sample{T,U}) where {A<:𝔻,B<:𝔻,T,U}
    return Sample{T,U}(swap_domain(A(), B(), state(s)), energy(s), reads(s))
end

function swap_domain(::A, ::B, ω::AbstractSampleSet{T,U}) where {A<:𝔻,B<:𝔻,T,U<:Integer}
    return SampleSet{T,U}(swap_domain.(A(), B(), ω), deepcopy(metadata(ω)))
end

state(ω::AbstractSampleSet, i::Integer)  = state(ω[i])
reads(ω::AbstractSampleSet)              = sum(reads.(ω))
reads(ω::AbstractSampleSet, i::Integer)  = reads(ω[i])
energy(ω::AbstractSampleSet, i::Integer) = energy(ω[i])

function Base.getindex(ω::AbstractSampleSet, i::Integer, j::Integer)
    return getindex(getindex(ω, i), j)
end

@doc raw"""
    SampleSet{T,U}(
        data::Vector{Sample{T,U}},
        metadata::Dict{String, Any},
    ) where {T,U}

It compresses repeated states by adding up the `reads` field.
It was inspired by [1], with a few tweaks.

!!! info
    A `SampleSet{T,U}` was designed to be read-only.
    It is optimized to support queries over the solution set.

## References
[1] https://docs.ocean.dwavesys.com/en/stable/docs_dimod/reference/S.html#dimod.SampleSet
""" struct SampleSet{T,U} <: AbstractSampleSet{T,U}
    data::Vector{Sample{T,U}}
    metadata::Dict{String,Any}

    # ~ Empty SampleSet ~ #
    function SampleSet{T,U}() where {T,U}
        new{T,U}(Sample{T,U}[], Dict{String,Any}())
    end

    # ~ Default Constructor ~ #
    function SampleSet{T,U}(
        samples::Vector{Sample{T,U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {T,U}
        data = sort(compress(samples))

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(data, metadata)
    end
end

function SampleSet{T,U}(
    model::Any,
    states::Vector{Vector{U}},
    metadata::Union{Dict{String,Any},Nothing} = nothing,
) where {T,U}
    data = [Sample{T,U}(state, QUBOTools.energy(model, state)) for state in states]

    return SampleSet{T,U}(data, metadata)
end

SampleSet{T}(args...; kws...) where {T}  = SampleSet{T,Int}(args...; kws...)
SampleSet(args...; kws...)               = SampleSet{Float64}(args...; kws...)
Base.copy(ω::SampleSet{T,U}) where {T,U} = SampleSet{T,U}(copy(ω.data), deepcopy(ω.metadata))

Base.:(==)(ω::SampleSet{T,U}, η::SampleSet{T,U}) where {T,U} = (ω.data == η.data)

Base.length(ω::SampleSet)  = length(ω.data)
Base.isempty(ω::SampleSet) = isempty(ω.data)
Base.empty!(ω::SampleSet)  = empty!(ω.data)

Base.getindex(ω::SampleSet, i::Integer) = ω.data[i]

metadata(ω::SampleSet) = ω.metadata

@doc raw"""
""" struct SamplePool{T,U} <: AbstractSampleSet{T,U}
    size::Int
    data::Vector{Sample{T,U}}
    metadata::Dict{String,Any}

    function SamplePool{T,U}(
        size::Integer,
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {T,U}
        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        data = sizehint!(Sample{T,U}[], size)

        return new{T,U}(size, data, metadata)
    end
end

SamplePool{T}(args...; kws...) where {T} = SamplePool{T,Int}(args...; kws...)
SamplePool(args...; kws...)              = SamplePool{Float64}(args...; kws...)

Base.:(==)(ω::SamplePool{T,U}, η::SamplePool{T,U}) where {T,U} = (ω.data == η.data)

Base.length(ω::SamplePool)               = length(ω.data)
Base.getindex(ω::SamplePool, i::Integer) = ω.data[i]

function Base.push!(ω::SamplePool{T,U}, ψ::Vector{U}, λ::T, r::Integer = 1) where {T,U}
    push!(ω, Sample{T,U}(ψ, λ, r))
end

function Base.push!(ω::SamplePool{T,U}, s::Sample{T,U}) where {T,U}
    # Fast track
    if length(ω) == ω.size && energy(ω[end]) < energy(s) # full pool
        return ω
    end

    r = searchsorted(ω.data, s)
    i = first(r)
    j = last(r)

    for k = i:j
        z = ω[k]

        if s == z
            ω.data[k] = merge(s, z)

            return ω
        end
    end

    if length(ω) < ω.size
        insert!(ω.data, i, s)
    elseif s < ω[end]
        pop!(insert!(ω.data, i, s))
    end

    return ω
end

SampleSet(ω::SamplePool{T,U}) where {T,U} = SampleSet{T,U}(ω.data, deepcopy(metadata(ω)))

function SamplePool(size::Integer, ω::SampleSet{T,U}) where {T,U}
    η = SamplePool{T,U}(size, deepcopy(metadata(ω)))

    push!(η, ω.data...)

    return η
end