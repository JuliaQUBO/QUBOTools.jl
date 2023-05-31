function tts(solution::AbstractSolution{T,U}, λ::T, s::Float64 = 0.99) where {T,U}
    if isempty(solution)
        return NaN
    end

    t = effective_time(solution)
    p = success_rate(solution, λ)

    return tts(t, p, s)
end

function tts(t::Float64, p::Float64, s::Float64 = 0.99)
    return t * log(1 - s) / log(1 - p)
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

            if value(sample) <= λ
                s += k
            end
        end

        return s / r
    end
end
