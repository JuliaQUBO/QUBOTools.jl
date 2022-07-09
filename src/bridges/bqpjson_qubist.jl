function Base.convert(::Type{<:Qubist}, model::BQPJSON{BoolDomain})
    convert(Qubist{SpinDomain}, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:Qubist}, model::BQPJSON{SpinDomain})
    sites = isempty(model.variable_ids) ? 0 : 1 + maximum(model.variable_ids)
    lines = length(model.linear_terms) + length(model.quadratic_terms)

    linear_terms    = copy(model.linear_terms)
    quadratic_terms = copy(model.quadratic_terms)

    Qubist{SpinDomain}(
        sites,
        lines,
        linear_terms,
        quadratic_terms,
    )
end

function Base.convert(::Type{<:BQPJSON{BoolDomain}}, model::Qubist)
    convert(BQPJSON{BoolDomain}, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::Qubist)
    id              = 0
    version         = BQPJSON_VERSION_LATEST
    variable_ids    = Set{Int}()
    variable_domain = "spin"
    scale           = 1.0
    offset          = 0.0
    linear_terms    = copy(model.linear_terms)
    quadratic_terms = copy(model.quadratic_terms)
    metadata        = Dict{String, Any}()
    description     = nothing
    solutions       = nothing

    for i in keys(linear_terms)
        push!(variable_ids, i)
    end

    for (i, j) in keys(quadratic_terms)
        push!(variable_ids, i)
        push!(variable_ids, j)
    end

    BQPJSON{SpinDomain}(
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

function isvalidbridge(source::BQPJSON{SpinDomain}, target::BQPJSON{SpinDomain}, ::Type{<:Qubist}; kw...)
    # Obs:
    # 1. id, offset, scale is lost
    source.version == target.version &&
    isapproxdict(source.linear_terms, target.linear_terms; kw...) &&
    isapproxdict(source.quadratic_terms, target.quadratic_terms; kw...)
end