function success_rate(sampleset::SampleSet{T}, λ::T) where {T}
    if isempty(sampleset)
        return NaN
    else
        s = 0
        r = 0

        for sample in sampleset
            if sample.value <= λ
                s += sample.reads
            end

            r += sample.reads
        end

        return s / r
    end
end

function tts(sampleset::SampleSet{T}, λ::T, s::Float64 = 0.99) where {T}
    if isempty(sampleset)
        return NaN
    end

    t = effective_time(sampleset)
    p = success_rate(sampleset, λ)

    return tts(t, p, s)
end

function tts(t::Float64, p::Float64, s::Float64 = 0.99)
    return t * log(1 - s) / log(1 - p)
end
