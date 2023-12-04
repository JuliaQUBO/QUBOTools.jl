function total_time(sol::AbstractSolution)
    data = metadata(sol)::Dict{String,Any}

    if !haskey(data, "time")
        return NaN
    end

    time_data = data["time"]::Dict{String,Any}

    if !haskey(time_data, "total")
        return NaN
    else
        return time_data["total"]::Float64
    end
end

function effective_time(sol::AbstractSolution)
    data = metadata(sol)::Dict{String,Any}

    if !haskey(data, "time")
        return NaN
    end

    time_data = data["time"]::Dict{String,Any}

    if !haskey(time_data, "effective")
        return total_time(sol)
    else
        return time_data["effective"]::Float64
    end
end

function success_rate(solution::AbstractSolution{T,U}, λ::T) where {T,U}
    if isempty(solution)
        return NaN
    else
        r = 0
        s = 0

        for sample in solution
            k = reads(sample)
            r += k

            if sense(solution) === Min
                if value(sample) <= λ
                    s += k
                end
            else # sense(solution) === Max
                if value(sample) >= λ
                    s += k
                end
            end
        end

        return s / r
    end
end

function time_to_target(solution::AbstractSolution{T,U}, λ::T, s::Float64 = 0.99) where {T,U}
    if isempty(solution)
        return NaN
    end

    t = effective_time(solution)
    p = success_rate(solution, λ)

    return time_to_target(t, p, s)
end

function time_to_target(t::Float64, p::Float64, s::Float64 = 0.99)
    @assert 0 <= p <= 1 && 0 <= s <= 1

    if isnan(p) || isnan(t)
        return NaN
    elseif iszero(p)
        return Inf
    else
        return t * log2(1 - s) / log2(1 - p)
    end
end

# function opt_tts(
#     solution::AbstractVector{S},
#     λ::T,
#     s::Float64 = 0.99,
#     q::Float64 = 0.5,
# ) where {T,U,S<:AbstractSolution{T,U}}
#     if isempty(solution)
#         return NaN
#     end

#     t = effective_time.(solution)
#     p = success_rate.(solution, λ)

#     return opt_tts(t, p, s, q)
# end

# function opt_tts(
#     t::AbstractVector{T},
#     p::AbstractVector{T},
#     s::Float64 = 0.99,
#     q::Float64 = 0.5,
# ) where {T}
#     return quantile(time_to_target.(t, p, s), q)
# end

function hamming_distance(ψ::State{U}, φ::State{U}) where {U}
    @assert length(ψ) == length(φ)

    d = 0

    for i in eachindex(ψ)
        if ψ[i] != φ[i]
            d += 1
        end
    end

    return d
end
