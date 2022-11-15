function bridge(::Type{BQPJSON{D}}, model::MiniZinc{D}) where {D<:𝔻}
    return BQPJSON{D}(copy(backend(model)))
end