@doc raw"""
    SampleSet{T,U}(
        data::Vector{Sample{T,U}},
        metadata::Dict{String,Any};
        sense::Sense = Min,
        domain::Domain = 𝔹,
    ) where {T,U}

It compresses repeated states by adding up the `reads` field.
It was inspired by [^dwave], with a few tweaks.

!!! info
    A `SampleSet{T,U}` was designed to be read-only.
    It is optimized to support queries over the solution set.

## References
[^dwave]:
    [ocean docs](https://docs.ocean.dwavesys.com/en/stable/docs_dimod/reference/S.html#dimod.SampleSet)
"""
struct SampleSet{T,U} <: AbstractSolution{T,U}
    data::Vector{Sample{T,U}}
    metadata::Dict{String,Any}
    frame::Frame

    function SampleSet{T,U}(
        data::AbstractVector{S},
        metadata::Union{Dict{String,Any},Nothing} = nothing;
        sense::Union{Sense,Symbol} = Min,
        domain::Union{Domain,Symbol} = 𝔹,
    ) where {T,U,S<:Sample{T,U}}
        data = sort(data)

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(data, metadata, Frame(sense, domain))
    end

    function SampleSet{T,U}(
        metadata::Dict{String,Any};
        sense::Union{Sense,Symbol} = Min,
        domain::Union{Domain,Symbol} = 𝔹,
    ) where {T,U}
        return new{T,U}(Sample{T,U}[], metadata, Frame(sense, domain))
    end

    function SampleSet{T,U}(; sense::Sense = Min, domain::Domain = 𝔹) where {T,U}
        return new{T,U}(Sample{T,U}[], Dict{String,Any}(), sense, domain)
    end
end

function SampleSet{T,U}(
    x,
    Ψ::AbstractVector{S},
    metadata::Union{Dict{String,Any},Nothing} = nothing,
) where {T,U,S<:State{U}}
    data = Vector{Sample{T,U}}(undef, length(Ψ))

    for i in eachindex(data)
        ψ = Ψ[i]
        λ = value(x, ψ)

        data[i] = Sample{T,U}(ψ, λ)
    end

    return SampleSet{T,U}(data, metadata; sense = sense(x), domain = domain(x))
end

SampleSet{T}(args...; kws...) where {T} = SampleSet{T,Int}(args...; kws...)
SampleSet(args...; kws...)              = SampleSet{Float64}(args...; kws...)

Base.copy(ω::SampleSet{T,U}) where {T,U} = SampleSet{T,U}(
    collect(ω),
    deepcopy(metadata(ω));
    sense = sense(ω),
    domain = domain(ω),
)

Base.:(==)(ω::SampleSet{T,U}, η::SampleSet{T,U}) where {T,U} = (ω.data == η.data)

Base.length(ω::SampleSet)  = length(ω.data)
Base.isempty(ω::SampleSet) = isempty(ω.data)

Base.collect(ω::SampleSet)              = collect(ω.data)
Base.getindex(ω::SampleSet, i::Integer) = ω.data[i]

Base.iterate(ω::SampleSet)             = iterate(ω.data)
Base.iterate(ω::SampleSet, i::Integer) = iterate(ω.data, i)

frame(ω::SampleSet)  = ω.frame
sense(ω::SampleSet)  = sense(frame(ω))
domain(ω::SampleSet) = domain(frame(ω))

metadata(ω::SampleSet) = ω.metadata

function cast(route::Route{S}, ω::SampleSet{T,U}) where {T,U,S<:Sense}
    return SampleSet{T,U}(
        Vector{Sample{T,U}}(cast.(route, ω)),
        deepcopy(metadata(ω));
        sense  = last(route),
        domain = domain(ω),
    )
end

function cast(route::Route{D}, ω::SampleSet{T,U}) where {T,U,D<:Domain}
    return SampleSet{T,U}(
        Vector{Sample{T,U}}(cast.(route, ω)),
        deepcopy(metadata(ω));
        sense  = sense(ω),
        domain = last(route),
    )
end
