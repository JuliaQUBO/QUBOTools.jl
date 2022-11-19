# BQPJSON{D} → MiniZinc{D}
function bridge(::Type{MiniZinc{D}}, model::BQPJSON{D}) where {D<:𝔻}
    return MiniZinc{D}(copy(backend(model)))
end

# BQPJSON{SpinDomain} → Qubist{SpinDomain}
function bridge(::Type{Qubist{SpinDomain}}, model::BQPJSON{SpinDomain})
    variables = QUBOTools.variables(model) 

    sites = isempty(variables) ? 0 : 1 + maximum(variables)
    lines = linear_size(model) + quadratic_size(model)

    return Qubist{SpinDomain}(
        copy(backend(model));
        sites=sites,
        lines=lines
    )
end

# BQPJSON{BoolDomain} → QUBO{BoolDomain}
function bridge(::Type{QUBO{BoolDomain}}, model::BQPJSON{BoolDomain})
    variables = QUBOTools.variables(model)

    max_index     = isempty(variables) ? 0 : 1 + maximum(variables)
    num_diagonals = linear_size(model)
    num_elements  = quadratic_size(model)

    return QUBO{BoolDomain}(
        copy(backend(model));
        max_index=max_index,
        num_diagonals=num_diagonals,
        num_elements=num_elements
    )
end
