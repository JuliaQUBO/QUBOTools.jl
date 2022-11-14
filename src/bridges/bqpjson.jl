# BQPJSON{D} → MiniZinc{D}
function bridge(::Type{<:MiniZinc}, model::BQPJSON{D}) where {D<:𝔻}
    return bridge(MiniZinc{D}, model)
end

function bridge(::Type{<:MiniZinc{D}}, model::BQPJSON{D}) where {D<:𝔻}
    return MiniZinc{D}(copy(backend(model)))
end

# BQPJSON{A} → MiniZinc{B}
function bridge(::Type{<:MiniZinc{B}}, model::BQPJSON{A}) where {A<:𝔻,B<:𝔻}
    return bridge(MiniZinc{B}, bridge(BQPJSON{B}, model))
end

# BQPJSON{BoolDomain} → Qubist{SpinDomain}
function bridge(::Type{M}, model::BQPJSON{BoolDomain}) where {M<:Qubist}
    return bridge(Qubist{SpinDomain}, bridge(BQPJSON{SpinDomain}, model))
end

# BQPJSON{SpinDomain} → Qubist{SpinDomain}
function bridge(::Type{M}, model::BQPJSON{SpinDomain}) where {M<:Qubist}
    variables = QUBOTools.variables(model) 

    sites = isempty(variables) ? 0 : 1 + maximum(variables)
    lines = linear_size(model) + quadratic_size(model)

    return Qubist{SpinDomain}(
        copy(backend(model));
        sites=sites,
        lines=lines
    )
end

# BQPJSON{SpinDomain} → QUBO{BoolDomain}
function bridge(::Type{M}, model::BQPJSON{SpinDomain}) where {M<:QUBO}
    return bridge(QUBO{BoolDomain}, bridge(BQPJSON{BoolDomain}, model))
end

# BQPJSON{BoolDomain} → QUBO{BoolDomain}
function bridge(::Type{M}, model::BQPJSON{BoolDomain}) where {M<:QUBO}
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
