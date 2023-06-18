@doc raw"""
    Sample{T,U}(state::Vector{U}, value::T, reads::Integer) where{T,U}

"""
struct Sample{T<:Real,U<:Integer} <: AbstractSample{T,U}
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
value(s::Sample) = s.value
reads(s::Sample) = s.reads

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
                solution_error("All samples must have states of equal length")
            end

            sample
        else
            if value(cached) != value(sample)
                solution_error(
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