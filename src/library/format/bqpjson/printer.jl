function write_model(io::IO, model::AbstractModel, fmt::BQPJSON)
    data = Dict{Symbol,Any}(
        :linear_terms    => Dict{String,Any}[],
        :quadratic_terms => Dict{String,Any}[],
        :offset          => offset(model),
        :scale           => scale(model),
        :id              => id(model),
        :version         => fmt.version,
        :variable_domain => _BQPJSON_VARIABLE_DOMAIN(domain(model)),
        :variable_ids    => variables(model),
        :description     => description(model),
        :metadata        => metadata(model),
        :solution        => solution(model),
    )

    for (i, l) in linear_terms(model)
        push!(
            data[:linear_terms],
            Dict{String,Any}(
                "id"    => variable_inv(model, i),
                "coeff" => l,
            )
        )
    end

    for ((i, j), q) in quadratic_terms(model)
        push!(
            data[:quadratic_terms],
            Dict{String,Any}(
                "id_head" => variable_inv(model, i),
                "id_tail" => variable_inv(model, j),
                "coeff"   => q,
            )
        )
    end

    sort!(data[:linear_terms]   ; by=(lt) -> lt["id"])
    sort!(data[:quadratic_terms]; by=(qt) -> (qt["id_head"], qt["id_tail"]))

    json_data = Dict{String,Any}(
        "id"              => data[:id],
        "variable_domain" => data[:variable_domain],
        "linear_terms"    => data[:linear_terms],
        "quadratic_terms" => data[:quadratic_terms],
        "variable_ids"    => data[:variable_ids],
        "offset"          => data[:offset],
        "scale"           => data[:scale],
        "metadata"        => data[:metadata],
    )

    if isnothing(data[:version])
        json_data["version"] = string(_BQPJSON_VERSION_LATEST)
    else
        json_data["version"] = string(data[:version])
    end

    if !isnothing(data[:description])
        json_data["description"] = data[:description]
    end

    if !isnothing(data[:solution])
        sol_id = 0

        solutions = Dict{String,Any}[]

        for s in data[:solution]
            assignment = Dict{String,Any}[
                Dict{String,Any}(
                    "id"    => i,
                    "value" => state(s, i),
                ) for i in values(variable_map(model))
            ]

            for _ = 1:reads(s)
                push!(
                    solutions,
                    Dict{String,Any}(
                        "id"         => (sol_id += 1),
                        "assignment" => assignment,
                        "evaluation" => value(sample),
                    )
                )
            end
        end

        json_data["solutions"] = solutions
    end

    JSON.print(io, json_data, fmt.indent)

    return nothing
end