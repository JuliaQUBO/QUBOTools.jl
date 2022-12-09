function total_time(ω::SampleSet)
    if !haskey(ω.metadata, "time")
        return NaN
    elseif !haskey(ω.metadata["time"], "total")
        return NaN
    else
        return ω.metadata["time"]["total"]
    end
end

function effective_time(ω::SampleSet)
    if !haskey(ω.metadata, "time")
        return NaN
    elseif !haskey(ω.metadata["time"], "effective")
        return total_time(ω)
    else
        return ω.metadata["time"]["effective"]
    end
end