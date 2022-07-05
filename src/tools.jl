function isapprox_dict(x::Dict{K, T}, y::Dict{K, T}; kw...) where {K, T <: Number}
    (length(x) == length(y)) && all(haskey(y, k) && isapprox(x[k], y[k]; kw...) for k in keys(x))
end