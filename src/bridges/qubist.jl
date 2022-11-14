# Qubist{SpinDomain} → BQPJSON{BoolDomain}
function bridge(::Type{<:BQPJSON{BoolDomain}}, model::Qubist)
    return bridge(BQPJSON{BoolDomain}, bridge(BQPJSON{SpinDomain}, model))
end

# Qubist{SpinDomain} → BQPJSON{SpinDomain}
function bridge(::Type{<:BQPJSON{SpinDomain}}, model::Qubist)
    return BQPJSON{SpinDomain}(copy(backend(model)))
end
