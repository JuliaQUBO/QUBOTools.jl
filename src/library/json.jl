function _json_data(x)
    return x
end

function _json_data(x::AbstractDict)
    return Dict{String,Any}(string(k) => _json_data(v) for (k, v) in x)
end

function _json_data(x::AbstractVector)
    return [_json_data(v) for v in x]
end

function _json_object(x)
    return _json_data(x)::Dict{String,Any}
end
