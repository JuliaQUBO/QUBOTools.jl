const BQPJSON_SCHEMA = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "bqpjson.schema.json")))
const BQPJSON_VERSION_LATEST = v"1.0.0"

@doc raw"""
""" struct BQPJSON{D <: Domain} <: Model{D}
    data::Dict{String, Any}

    function BQPJSON{D}(data::Dict{String, Any}) where D <: Domain
        new{D}(data)
    end

    function BQPJSON(data::Dict{String, Any})
        if haskey(data, "variable_domain")
            if data["variable_domain"] == "spin"
                return BQPJSON{SpinDomain}(data)
            elseif data["variable_domain"] == "boolean"
                return BQPJSON{BoolDomain}(data)
            else
                error("'variable_domain' must be either 'spin' or 'bool'")
            end
        else
            error("Missing field 'variable_domain'")
        end
    end
end

function Base.read(io::IO, M::Type{<:BQPJSON})
    model = BQPJSON(JSON.parse(io))

    if !(model isa M)
        model = convert(M, model)
    end

    if isvalid(model)
        model
    else
        nothing
    end
end

function Base.write(io::IO, model::BQPJSON)
    JSON.print(io, model.data)
end

function Base.isvalid(model::BQPJSON{D}) where D
    if !isnothing(JSONSchema.validate(BQPJSON_SCHEMA, model.data))
        return false
    end

    if VersionNumber(model.data["version"]) !== BQPJSON_VERSION_LATEST
        return false
    end

    spin_var_domain = (model.data["variable_domain"] == "spin" && D <: SpinDomain)
    bool_var_domain = (model.data["variable_domain"] == "boolean" && D <: BoolDomain)

    if !spin_var_domain && !bool_var_domain
        return false
    end

    if model.data["scale"] < 0
        return false
    end

    var_ids = Set{Int}(model.data["variable_ids"])
    lt_vars = Set{Int}()

    for lt in model.data["linear_terms"]
        if lt["id"] ∉ var_ids || lt["id"] ∈ lt_vars
            return false
        end

        push!(lt_vars, lt["id"])
    end

    qt_var_pairs = Set{Tuple{Int, Int}}()

    for qt in model.data["quadratic_terms"]
        if qt["id_tail"] ∉ var_ids || qt["id_head"] ∉ var_ids || qt["id_tail"] == qt["id_head"]
            return false
        end

        pair = if qt["id_head"] < qt["id_tail"]
            (qt["id_head"], qt["id_tail"])
        else
            (qt["id_tail"], qt["id_head"])
        end

        if pair ∈ qt_var_pairs
            return false
        end

        push!(qt_var_pairs, pair)
    end

    if haskey(model.data, "solutions")
        solution_ids = Set{Int}()
        for solution in model.data["solutions"]
            if solution["id"] ∈ solution_ids
                return false
            end

            push!(solution_ids, solution["id"])

            sol_var_ids = Set{Int}()
            for assign in solution["assignment"]
                var_id = assign["id"]
                
                if (var_id ∉ var_ids) || (var_id ∈ sol_var_ids)
                    return false
                end

                push!(sol_var_ids, var_id)

                if spin_var_domain && !(assign["value"] == -1 || assign["value"] == 1)
                    return false
                end

                if bool_var_domain && !(assign["value"] == 0 || assign["value"] == 1)
                    return false
                end
            end
            
            if length(sol_var_ids) != length(var_ids)
                return false
            end
        end
    end

    return true
end

function Base.convert(::Type{<:BQPJSON{D}}, model::BQPJSON{D}) where D
    model
end

function Base.convert(::Type{<:BQPJSON{BoolDomain}}, model::BQPJSON{SpinDomain})
    offset = model.data["offset"]
    coeffs = Dict{Tuple{Int, Int}, Float64}()

    for linear_term in model.data["linear_terms"]
        i = linear_term["id"]
        h = linear_term["coeff"]
        coeffs[(i, i)] = 2.0 * h
        offset -= h
    end

    for quadratic_term in model.data["quadratic_terms"]
        i = quadratic_term["id_head"]
        j = quadratic_term["id_tail"]
        J = quadratic_term["coeff"]

        coeffs[(i, j)] = get(coeffs, (i, j), 0.0) + 4.0 * J
        coeffs[(i, i)] = get(coeffs, (i, i), 0.0) - 2.0 * J
        coeffs[(i, i)] = get(coeffs, (j, j), 0.0) - 2.0 * J
        offset += J
    end

    linear_terms = []
    quadratic_terms = []

    for (i, j) in sort(collect(keys(coeffs)))
        v = coeffs[(i, j)]
        if !iszero(v)
            if i == j
                push!(linear_terms, Dict("id" => i, "coeff" => v))
            else
                push!(quadratic_terms, Dict("id_head" => i, "id_tail" => j, "coeff" => v))
            end
        end
    end

    data = copy(model.data)
    data["variable_domain"] = "boolean"
    data["offset"] = offset
    data["linear_terms"] = linear_terms
    data["quadratic_terms"] = quadratic_terms

    if haskey(data, "solutions")
        for solution in data["solutions"]
            for assign in solution["assignment"]
                assign["value"] = (1 - assign["value"]) / 2
            end
        end
    end

    BQPJSON{BoolDomain}(data)
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::BQPJSON{BoolDomain})
    offset = model.data["offset"]
    coeffs = Dict{Tuple{Int, Int}, Float64}()

    for linear_term in model.data["linear_terms"]
        i = linear_term["id"]
        q = linear_term["coeff"]

        coeffs[(i, i)] = q / 2.0
        offset += q / 2.0
    end

    for quadratic_term in model.data["quadratic_terms"]
        i = quadratic_term["id_head"]
        j = quadratic_term["id_tail"]
        Q = quadratic_term["coeff"]

        coeffs[(i, j)] = get(coeffs, (i, j), 0.0) + Q / 4.0
        coeffs[(i, i)] = get(coeffs, (i, i), 0.0) + Q / 4.0
        coeffs[(j, j)] = get(coeffs, (j, j), 0.0) + Q / 4.0
        offset += Q / 4.0
    end

    linear_terms = []
    quadratic_terms = []

    for (i, j) in sort(collect(keys(coeffs)))
        v = coeffs[(i, j)]
        if !iszero(v)
            if i == j
                push!(linear_terms, Dict("id" => i, "coeff" => v))
            else
                push!(quadratic_terms, Dict("id_head" => i, "id_tail" => j, "coeff" => v))
            end
        end
    end

    data = copy(model.data)
    data["variable_domain"] = "spin"
    data["offset"] = offset
    data["linear_terms"] = linear_terms
    data["quadratic_terms"] = quadratic_terms

    if haskey(data, "solutions")
        for solution in data["solutions"]
            for assign in solution["assignment"]
                assign["value"] = 1 - 2 * assign["value"]
            end
        end
    end

    BQPJSON{SpinDomain}(data)
end