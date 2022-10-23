
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
        metadata::Union{Dict{String,Any},Nothing} = nothing
    ) where {T,U}
        data = sort(compress(samples))

        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        return new{T,U}(data, metadata)
    end

    function SampleSet{T,U}(
        model::Any,
        states::Vector{Vector{U}},
        metadata::Union{Dict{String,Any},Nothing} = nothing,
    ) where {T,U}
        data = [
            Sample{T,U}(state, QUBOTools.energy(model, state))
            for state in states
        ]

        return SampleSet{T,U}(data, metadata)
    end
end

SampleSet{T}(args...; kws...) where {T} = SampleSet{T,Int}(args...; kws...)
SampleSet(args...; kws...)              = SampleSet{Float64}(args...; kws...)

Base.copy(S::SampleSet{T,U}) where {T,U} = SampleSet{T,U}(copy(S.data), deepcopy(S.metadata))

@inline Base.:(==)(X::SampleSet{T,U}, Y::SampleSet{T,U}) where {T,U} = X.data == Y.data

@inline Base.length(S::SampleSet) = length(S.data)

@inline Base.size(S::SampleSet) = (size(S, 1), size(S, 2))

@inline function Base.size(S::SampleSet, axis::Integer)
    if axis == 1
        return length(S)
    elseif axis == 2 && !isempty(S)
        return length(S[begin])
    else
        return 1
    end
end

@inline Base.iterate(S::SampleSet) = iterate(S.data)
@inline Base.iterate(S::SampleSet, i::Integer) = iterate(S.data, i)
@inline Base.firstindex(::SampleSet) = 1
@inline Base.firstindex(::SampleSet, ::Integer) = 1
@inline Base.lastindex(S::SampleSet) = length(S)

@inline function Base.lastindex(S::SampleSet, axis::Integer)
    if axis == 1
        return length(S)
    elseif axis == 2 && !isempty(S)
        return length(S[begin])
    else
        return 1
    end
end

@inline Base.getindex(S::SampleSet, i::Integer)             = S.data[i]
@inline Base.getindex(S::SampleSet, i::Integer, j::Integer) = S.data[i].state[j]

@inline Base.isempty(S::SampleSet) = isempty(S.data)
@inline Base.empty!(S::SampleSet)  = empty!(S.data)

function Base.show(io::IO, S::SampleSet{T,U}) where {T,U}
    if isempty(S)
        println(io, "Empty SampleSet{$T,$U}")
        return nothing
    end
    
    println(io, "SampleSet{$T,$U} with $(length(S)) samples:")

    for (i, s) in enumerate(S)
        print(io, "  ")

        if i < 10
            println(io, s)
        else
            println(io, "…")
            break
        end
    end

    return nothing
end