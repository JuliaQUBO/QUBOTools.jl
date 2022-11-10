struct SamplePool{T,U} <: AbstractSampleSet{T,U}
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

Base.length(S) = length(S.data)
Base.getindex(S::SamplePool, i::Integer) = S.data[i]

function Base.push!(S::SamplePool{T,U}, s::Sample{T,U}) where {T,U}
    a, b = extrema(searchsorted(S.data, s))

    for i = a:b
        z = S[i]

        if s == z
            return (S.data[i] = merge(s, z))
        end
    end

    if length(S) < S.size
        return insert!(S.data, a, s)
    elseif s < S[end]
        pop!(S.data)
        return insert!(S.data, a, s)
    else
        return nothing
    end
end