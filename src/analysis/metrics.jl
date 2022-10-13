function success_rate(sampleset::SampleSet{<:Any,T}, e::T) where {T}
    if isempty(sampleset)
        return NaN
    else
        return sum(
            sample.reads
            for sample in sampleset
            if sample.value <= e
        ) / sampleset.reads
    end
end

function tts(sampleset::SampleSet{<:Any,T}, e::T; s::Float64 = 0.99) where {T}
    if isempty(sampleset)
        return NaN
    end

    t = effective_time(sampleset)
    p = success_rate(sampleset, e)

    return tts(t, p, s)
end

function tts(t::Float64, p::Float64, s::Float64 = 0.99)
    return t * log(1 - s) / log(1 - p)
end
