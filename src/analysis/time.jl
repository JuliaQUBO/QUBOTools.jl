function total_time(S::SampleSet)
    if !haskey(S.metadata, "time")
        return NaN
    elseif !haskey(S.metadata["time"], "total")
        return NaN
    else
        return S.metadata["time"]["total"]
    end
end

function effective_time(S::SampleSet)
    if !haskey(S.metadata, "time")
        return NaN
    elseif !haskey(S.metadata["time"], "effective")
        return total_time(S)
    else
        return S.metadata["time"]["effective"]
    end
end