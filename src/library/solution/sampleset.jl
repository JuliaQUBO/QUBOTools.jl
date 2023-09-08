@doc raw"""
    SampleSet{T,U}(
        data::Vector{Sample{T,U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing;
        sense::Union{Sense,Symbol}   = :min,
        domain::Union{Domain,Symbol} = :bool,
    ) where {T,U}

Reference implementation of [`QUBOTools.AbstractSolution`](@ref).

It was inspired by D-Wave's SampleSet[^dwave], with a few tweaks. For example, samples
are automatically sorted upon instantiation and repeated samples are merged by adding
up their `reads` field. Also, the solution frame is stored, allowing for queries and
[`cast`](@ref) operations.

[^dwave]:
    D-Wave Ocean SDK [{docs}](https://docs.ocean.dwavesys.com/en/stable/docs_dimod/reference/sampleset.html#id1)
"""
struct SampleSet{T,U} <: AbstractSolution{T,U}
    data::Vector{Sample{T,U}}
    metadata::Dict{String,Any}
    frame::Frame

    # Canonical constructor
    function SampleSet{T,U}(
        data::AbstractVector{S},
        metadata::Union{Dict{String,Any},Nothing} = nothing;
        sense::Union{Sense,Symbol}   = :min,
        domain::Union{Domain,Symbol} = :bool,
    ) where {T,U,S<:Sample{T,U}}
        frame = Frame(sense, domain)

        data = _sort_and_merge(data, QUBOTools.sense(frame))

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(data, metadata, frame)
    end

    # Short-cut: Empty Set + Metadata
    function SampleSet{T,U}(
        metadata::Union{Dict{String,Any},Nothing} = nothing;
        sense::Union{Sense,Symbol}   = :min,
        domain::Union{Domain,Symbol} = :bool,
    ) where {T,U}
        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(Sample{T,U}[], metadata, Frame(sense, domain))
    end
end

# Fallback constructor
function SampleSet{T,U}(
    src::Any,
    Ψ::AbstractVector{S},
    metadata::Union{Dict{String,Any},Nothing} = nothing,
) where {T,U,S<:State{U}}
    data = Vector{Sample{T,U}}(undef, length(Ψ))

    for i in eachindex(data)
        ψ = Ψ[i]
        λ = value(src, ψ)

        data[i] = Sample{T,U}(ψ, λ)
    end

    return SampleSet{T,U}(data, metadata; sense = sense(x), domain = domain(x))
end

# Type Aliases
SampleSet{T}(args...; kws...) where {T} = SampleSet{T,Int}(args...; kws...)
SampleSet(args...; kws...)              = SampleSet{Float64,Int}(args...; kws...)

function Base.copy(sol::SampleSet{T,U}) where {T,U}
    return SampleSet{T,U}(
        collect(sol),
        deepcopy(metadata(sol));
        sense  = sense(sol),
        domain = domain(sol),
    )
end

Base.length(sol::SampleSet)  = length(sol.data)
Base.isempty(sol::SampleSet) = isempty(sol.data)

function dimension(sol::SampleSet)
    if isempty(sol)
        return 0
    else
        return dimension(first(sol))
    end
end

Base.collect(sol::SampleSet)              = collect(sol.data)
Base.getindex(sol::SampleSet, i::Integer) = sol.data[i]

Base.iterate(sol::SampleSet)             = iterate(sol.data)
Base.iterate(sol::SampleSet, i::Integer) = iterate(sol.data, i)

metadata(sol::SampleSet) = sol.metadata

frame(sol::SampleSet)  = sol.frame
sense(sol::SampleSet)  = sense(frame(sol))
domain(sol::SampleSet) = domain(frame(sol))

function cast((s,t)::Route{S}, sol::SampleSet{T,U}) where {T,U,S<:Sense}
    if s === t
        return sol
    else
        return SampleSet{T,U}(
            Vector{Sample{T,U}}(cast.(s => t, sol)),
            deepcopy(metadata(sol));
            sense  = t,
            domain = domain(sol),
        )
    end
end

function cast((s,t)::Route{D}, sol::SampleSet{T,U}) where {T,U,D<:Domain}
    if s === t
        return sol
    elseif s === 𝔹 && t === 𝕊 || s === 𝕊 && t === 𝔹
        return SampleSet{T,U}(
            Vector{Sample{T,U}}(cast.(s => t, sol)),
            deepcopy(metadata(sol));
            sense  = sense(sol),
            domain = t,
        )
    else
        casting_error(s => t, sol)

        return nothing
    end
end
