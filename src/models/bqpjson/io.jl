function Base.read(io::IO, M::Type{<:BQPJSON})
    data = JSON.parse(io)

    let report = JSONSchema.validate(BQPJSON_SCHEMA, data)
        if !isnothing(report)
            error("Invalid data:\n$(report)")
        end
    end

    # ~*~ Validation ~*~
    id = data["id"]

    version = VersionNumber(data["version"])

    if version !== BQPJSON_VERSION_LATEST
        error("Invalid data: Incorrect bqpjson version '$version'")
    end

    variable_domain = data["variable_domain"]

    D = if variable_domain == "boolean"
        BoolDomain
    elseif variable_domain == "spin"
        SpinDomain
    else
        error("Invalid data: Inconsistent variable domain '$variable_domain'")
    end

    offset = data["offset"]
    scale = data["scale"]

    if scale < 0.0
        error("Invalid data: Negative scale factor '$scale'")
    end

    variable_map = Dict{Int,Int}(i => k for (k, i) in enumerate(data["variable_ids"]))
    linear_terms = Dict{Int,Float64}()

    for lt in data["linear_terms"]
        i = lt["id"]
        l = lt["coeff"]
        i = if !haskey(variable_map, i)
            error("Invalid data: Unknown variable id '$i'")
        else
            variable_map[i]
        end
        linear_terms[i] = get(linear_terms, i, 0.0) + l
    end

    quadratic_terms = Dict{Tuple{Int,Int},Float64}()

    for qt in data["quadratic_terms"]
        i = qt["id_head"]
        j = qt["id_tail"]
        q = qt["coeff"]
        i, j = if i == j
            error("Invalid data: Twin quadratic term '$i, $j'")
        elseif !haskey(variable_map, i)
            error("Invalid data: Unknown variable id '$i'")
        elseif !haskey(variable_map, j)
            error("Invalid data: Unknown variable id '$j'")
        elseif j < i
            variable_map[j], variable_map[i]
        else
            variable_map[i], variable_map[j]
        end
        quadratic_terms[(i, j)] = get(quadratic_terms, (i, j), 0.0) + q
    end

    description = get(data, "description", nothing)
    metadata = deepcopy(data["metadata"])
    solutions = get(data, "solutions", nothing)

    if !isnothing(solutions)
        sol_ids = Set{Int}()
        for solution in data["solutions"]
            i = solution["id"]

            if i ∈ sol_ids
                error("Invalid data: Duplicate solution id '$i'")
                push!(sol_ids, i)
            end

            var_ids = Set{Int}()

            for assign in solution["assignment"]
                j = assign["id"]
                v = assign["value"]

                if !haskey(variable_map, j)
                    error("Invalid data: Unknown variable id '$j' in assignment")
                elseif j ∈ var_ids
                    error("Invalid data: Duplicate variable id '$j' in assignment")
                elseif !BQPJSON_VALIDATE_DOMAIN(v, D)
                    error("Invalid data: Variable assignment '$value' out of domain")
                end

                push!(var_ids, j)
            end

            if length(var_ids) != length(variable_map)
                error("Invalid data: Length mismatch between variable set and solution assignment")
            end
        end
    end

    model = BQPJSON{D}(
        linear_terms,
        quadratic_terms,
        variable_map,
        offset,
        scale,
        id,
        version,
        description,
        metadata,
        solutions,
    )

    convert(M, model)
end

function Base.write(io::IO, model::BQPJSON{D}) where {D<:VariableDomain}
    linear_terms = Dict{String,Any}[]
    quadratic_terms = Dict{String,Any}[]
    offset = BQPIO.offset(model)
    scale = BQPIO.scale(model)
    id = BQPIO.id(model)
    version = BQPIO.version(model)
    variable_domain = BQPJSON_VARIABLE_DOMAIN(D)
    metadata = BQPIO.metadata(model)

    for (i, l) in BQPIO.linear_terms(model)
        push!(
            linear_terms,
            Dict{String,Any}(
                "id" => BQPIO.variable_inv(model, i),
                "coeff" => l,
            )
        )
    end

    for ((i, j), q) in BQPIO.quadratic_terms(model)
        push!(
            quadratic_terms,
            Dict{String,Any}(
                "id_head" => BQPIO.variable_inv(model, i),
                "id_tail" => BQPIO.variable_inv(model, j),
                "coeff" => q,
            )
        )
    end

    sort!(linear_terms; by=(lt) -> lt["id"])
    sort!(quadratic_terms; by=(qt) -> (qt["id_head"], qt["id_tail"]))

    variable_ids = BQPIO.variables(model)

    data = Dict{String,Any}(
        "id" => id,
        "version" => string(version),
        "variable_domain" => variable_domain,
        "linear_terms" => linear_terms,
        "quadratic_terms" => quadratic_terms,
        "variable_ids" => variable_ids,
        "offset" => offset,
        "scale" => scale,
        "metadata" => metadata,
    )

    description = BQPIO.description(model)

    if !isnothing(description)
        data["description"] = description
    end

    if !isnothing(model.solutions)
        data["solutions"] = deepcopy(model.solutions)
    else
        sampleset = BQPIO.sampleset(model)

        if !isnothing(sampleset)
            id = 0

            solutions = Dict{String,Any}[]

            for sample in sampleset
                assignment = Dict{String,Any}[
                    Dict{String,Any}(
                        "id" => i,
                        "value" => sample.state[j]
                    ) for (i, j) in BQPIO.variable_map(model)
                ]
                for _ = 1:sample.reads
                    push!(
                        solutions,
                        Dict{String,Any}(
                            "id" => (id += 1),
                            "assignment" => assignment,
                            "evaluation" => sample.value,
                        )
                    )
                end
            end

            data["solutions"] = solutions
        end
    end

    JSON.print(io, data)
end

function Base.convert(::Type{<:BQPJSON{B}}, model::BQPJSON{A}) where {A,B}
    backend = convert(BQPJSON_BACKEND_TYPE{B}, model.backend)
    solutions = deepcopy(model.solutions)

    if !isnothing(solutions)
        for solution in solutions
            for assign in solution["assignment"]
                assign["value"] = BQPJSON_SWAP_DOMAIN(assign["value"], A)
            end
        end
    end

    BQPJSON{B}(backend, solutions)
end