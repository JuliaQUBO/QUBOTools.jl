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

@inline Base.:(==)(u::Sample{T,U}, v::Sample{T,U}) where {T,U} = u.state == v.state
@inline Base.:(<)(u::Sample{T,U}, v::Sample{T,U}) where {T,U}  = u.value < v.value

@inline function Base.isequal(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return isequal(u.reads, v.reads) &&
           isequal(u.value, v.value) &&
           isequal(u.state, v.state)
end

@inline function Base.isless(u::Sample{T,U}, v::Sample{T,U}) where {T,U}
    return isequal(u.value, v.value) ? isless(u.state, v.state) : isless(u.value, v.value)
end

@inline Base.length(x::Sample) = length(x.state)

@inline Base.show(io::IO, s::Sample) = join(io, ifelse.(s.state .> 0, '↓', '↑');)

@propagate_inbounds Base.getindex(s::Sample, i::Integer) = s.state[i]

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