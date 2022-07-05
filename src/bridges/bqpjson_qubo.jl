function Base.convert(::Type{BQPJSON{SpinDomain}}, model::QUBO)
    convert(BQPJSON{SpinDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{BQPJSON{BoolDomain}}, model::QUBO)
    id              = model.id
    version         = BQPJSON_VERSION_LATEST
    variable_ids    = Set{Int}()
    variable_domain = "boolean"
    scale           = model.scale
    offset          = model.offset
    terms           = Dict{Tuple{Int, Int}, Float64}()
    metadata        = deepcopy(model.metadata)
    description     = model.description
    solutions       = nothing

    for (i, l) in model.linear_terms
        push!(variable_ids, i)
        terms[(i, i)] = get(terms, (i, i), 0.0) + l
    end

    for ((i, j), q) in model.quadratic_terms
        push!(variable_ids, i, j)
        terms[(i, j)] = get(terms, (i, j), 0.0) + q
    end

    BQPJSON{BoolDomain}(
        id,
        version,
        variable_ids,
        variable_domain,
        scale,
        offset,
        terms,
        metadata,
        description,
        solutions,
    )
end

function Base.convert(::Type{<:QUBO}, model::BQPJSON{SpinDomain})
    convert(QUBO{BoolDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{<:QUBO}, model::BQPJSON{BoolDomain})
    id     = model.id
    scale  = model.scale
    offset = model.offset

    linear_terms    = Dict{Int, Float64}()
    quadratic_terms = Dict{Tuple{Int, Int}, Float64}()

    for ((i, j), q) in model.terms
        if i == j # linear
            linear_terms[i] = get(linear_terms, i, 0.0) + q
        else # quadratic
            quadratic_terms[(i, j)] = get(quadratic_terms, (i, j), 0.0) + q
        end
    end

    max_index     = isempty(model.variable_ids) ? 0 : 1 + maximum(model.variable_ids)
    num_diagonals = length(linear_terms)
    num_elements  = length(quadratic_terms)

    description = model.description
    metadata    = deepcopy(model.metadata)

    QUBO{BoolDomain}(
        id,
        scale,
        offset,
        max_index,
        num_diagonals,
        num_elements,
        linear_terms,
        quadratic_terms,
        description,
        metadata,
    )
end