function bridge(::Type{<:BQPJSON}, model::MiniZinc{D}) where {D<:𝔻}
    return bridge(BQPJSON{D}, model)
end

function bridge(::Type{<:BQPJSON{B}}, model::MiniZinc{A}) where {A<:𝔻,B<:𝔻}
    return bridge(BQPJSON{B}, bridge(MiniZinc{B}, model))
end

function bridge(::Type{<:BQPJSON{D}}, model::MiniZinc{D}) where {D<:𝔻}
    return BQPJSON{D}(copy(backend(model)))
end