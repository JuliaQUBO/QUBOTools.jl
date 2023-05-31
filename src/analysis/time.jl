function total_time(ω::AbstractSolution)
    data = metadata(ω)::Dict{String,Any}

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

function effective_time(ω::AbstractSolution)
    data = metadata(ω)::Dict{String,Any}

    if !haskey(data, "time")
        return NaN
    end

    time_data = data["time"]::Dict{String,Any}

    if !haskey(time_data, "effective")
        return total_time(ω)
    else
        return time_data["effective"]::Float64
    end
end