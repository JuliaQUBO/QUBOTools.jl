# QUBO{BoolDomain} → BQPJSON{SpinDomain}
function bridge(::Type{BQPJSON{SpinDomain}}, model::QUBO)
    return bridge(BQPJSON{SpinDomain}, bridge(BQPJSON{BoolDomain}, model))
end

# QUBO{BoolDomain} → BQPJSON{BoolDomain}
function bridge(::Type{BQPJSON{BoolDomain}}, model::QUBO)
    backend   = copy(QUBOTools.backend(model))
    solutions = nothing

    return BQPJSON{BoolDomain}(backend, solutions)
end
