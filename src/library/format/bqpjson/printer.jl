function write_model(io::IO, model::AbstractModel{V}, fmt::BQPJSON) where {V<:Integer}
    if fmt.version === v"1.0.0"
        _print_bqpjson_model_v1_0_0(io, model, fmt)
    else
        format_error("Invalid BQPJSON version '$(fmt.version)'")
    end
    
    return nothing
end

function _print_bqpjson_model_v1_0_0(io::IO, model::AbstractModel{V}, fmt::BQPJSON) where {V<:Integer}
    json_data = Dict{String,Any}(
        "id"              => 0,
        "variable_domain" => _BQPJSON_VARIABLE_DOMAIN(domain(model)),
        "linear_terms"    => Dict{String,Any}[],
        "quadratic_terms" => Dict{String,Any}[],
        "variable_ids"    => variables(model),
        "scale"           => scale(model),
        "offset"          => offset(model),
        "metadata"        => Dict{String,Any}(),
        "version"         => string(fmt.version),
    )

    for (i, l) in linear_terms(model)
        push!(
            json_data["linear_terms"],
            Dict{String,Any}("id" => variable(model, i), "coeff" => l),
        )
    end

    for ((i, j), q) in quadratic_terms(model)
        push!(
            json_data["quadratic_terms"],
            Dict{String,Any}(
                "id_head" => variable(model, i),
                "id_tail" => variable(model, j),
                "coeff"   => q,
            ),
        )
    end

    sort!(json_data["linear_terms"]; by = (lt) -> lt["id"])
    sort!(json_data["quadratic_terms"]; by = (qt) -> (qt["id_head"], qt["id_tail"]))

    for (k, v) in metadata(model)
        if k == "id" && !isnothing(v)
            json_data["id"] = v
        elseif k == "description" && !isnothing(v)
            json_data["description"] = v
        else
            json_data["metadata"][k] = v
        end
    end

    sol = solution(model)

    if !isempty(sol)
        sol_id = 0

        solutions = Dict{String,Any}[]

        for s in sol
            assignment = Dict{String,Any}[
                Dict{String,Any}("id" => i, "value" => state(s, i))
                for i in indices(model)
            ]

            evaluation = value(s)

            for _ = 1:reads(s)
                push!(
                    solutions,
                    Dict{String,Any}(
                        "id"         => (sol_id += 1),
                        "assignment" => assignment,
                        "evaluation" => evaluation,
                    ),
                )
            end
        end

        json_data["solutions"] = solutions
    end

    JSON.print(io, json_data, fmt.indent)

    return nothing
end
