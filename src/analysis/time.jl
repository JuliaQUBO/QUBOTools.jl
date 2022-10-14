function total_time(sampleset::SampleSet)
    if !haskey(sampleset.metadata, "time")
        return NaN
    elseif !haskey(sampleset.metadata["time"], "total")
        return NaN
    else
        return sampleset.metadata["time"]["total"]
    end
end

function effective_time(sampleset::SampleSet)
    if !haskey(sampleset.metadata, "time")
        return NaN
    elseif !haskey(sampleset.metadata["time"], "effective")
        return total_time(sampleset)
    else
        return sampleset.metadata["time"]["effective"]
    end
end