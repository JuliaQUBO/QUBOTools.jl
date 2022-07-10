function Base.convert(::Type{BQPJSON{SpinDomain}}, model::QUBO)
    convert(BQPJSON{SpinDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{BQPJSON{BoolDomain}}, model::QUBO)
    backend   = copy(model.backend)
    solutions = nothing

    BQPJSON{BoolDomain}(backend, solutions)
end

function Base.convert(::Type{<:QUBO}, model::BQPJSON{SpinDomain})
    convert(QUBO{BoolDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{<:QUBO}, model::BQPJSON{BoolDomain})
    backend       = copy(model.backend)
    max_index     = isempty(backend.variable_map) ? 0 : 1 + maximum(keys(backend.variable_map))
    num_diagonals = length(backend.linear_terms)
    num_elements  = length(backend.quadratic_terms)

    QUBO{BoolDomain}(
        backend,
        max_index,
        num_diagonals,
        num_elements,
    )
end