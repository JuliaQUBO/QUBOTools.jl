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
    linear_terms    = copy(model.linear_terms)
    quadratic_terms = copy(model.quadratic_terms)
    metadata        = deepcopy(model.metadata)
    description     = model.description
    solutions       = nothing

    for i in keys(linear_terms)
        push!(variable_ids, i)
    end

    for (i, j) in keys(quadratic_terms)
        push!(variable_ids, i)
        push!(variable_ids, j)
    end

    BQPJSON{BoolDomain}(
        id,
        version,
        variable_ids,
        variable_domain,
        scale,
        offset,
        linear_terms,
        quadratic_terms,
        metadata,
        description,
        solutions,
    )
end

function Base.convert(::Type{<:QUBO}, model::BQPJSON{SpinDomain})
    convert(QUBO{BoolDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{<:QUBO}, model::BQPJSON{BoolDomain})
    id              = model.id
    scale           = model.scale
    offset          = model.offset
    linear_terms    = copy(model.linear_terms)
    quadratic_terms = copy(model.quadratic_terms)

    max_index     = isempty(model.variable_ids) ? 0 : 1 + maximum(model.variable_ids)
    num_diagonals = length(linear_terms)
    num_elements  = length(quadratic_terms)

    metadata    = deepcopy(model.metadata)
    description = model.description

    QUBO{BoolDomain}(
        id,
        scale,
        offset,
        max_index,
        num_diagonals,
        num_elements,
        linear_terms,
        quadratic_terms,
        metadata,
        description,
    )
end

function isvalidbridge(source::BQPJSON{BoolDomain}, target::BQPJSON{BoolDomain}, ::Type{<:QUBO{BoolDomain}}; kw...)
    source.id              == target.id              &&
    source.version         == target.version         &&
    source.variable_ids    == target.variable_ids    &&
    source.variable_domain == target.variable_domain &&
    isapprox(source.scale , target.scale ; kw...)    &&
    isapprox(source.offset, target.offset; kw...)    &&
    isapproxdict(source.linear_terms   , target.linear_terms   ; kw...) &&
    isapproxdict(source.quadratic_terms, target.quadratic_terms; kw...) &&
    source.metadata        == target.metadata &&
    source.description     == target.description
end