function Base.convert(::Type{<:Qubist}, model::BQPJSON{BoolDomain})
    convert(Qubist{SpinDomain}, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:Qubist}, model::BQPJSON{SpinDomain})
    sites = isempty(model.variable_ids) ? 0 : 1 + maximum(model.variable_ids)
    lines = length(model.terms)

    linear_terms    = Dict{Int, Float64}()
    quadratic_terms = Dict{Tuple{Int, Int}, Float64}()

    for ((i, j), q) in model.terms
        if i == j # linear
            linear_terms[i] = get(linear_terms, i, 0.0) + q
        else # quadratic
            quadratic_terms[(i, j)] = get(quadratic_terms, (i, j), 0.0) + q
        end
    end

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
    terms           = Dict{Tuple{Int, Int}, Float64}()
    metadata        = Dict{String, Any}()
    description     = nothing
    solutions       = nothing

    for (i, h) in model.linear_terms
        push!(variable_ids, i)
        terms[(i, i)] = get(terms, (i, i), 0.0) + h
    end

    for ((i, j), J) in model.quadratic_terms
        push!(variable_ids, i, j)
        terms[(i, j)] = get(terms, (i, j), 0.0) + J
    end

    BQPJSON{SpinDomain}(
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

function isapproxbridge(source::BQPJSON{SpinDomain}, target::BQPJSON{SpinDomain}, ::Type{<:Qubist}; kw...)
    # Obs:
    # 1. id, offset, scale is lost
    source.version == target.version &&
    isapprox_dict(source.terms, target.terms; kw...)
end