function write_model(io::IO, model::AbstractModel{D}, ::BQPJSON{D}) where {D<:VariableDomain}
    data = Dict{Symbol,Any}(
        :linear_terms    => Dict{String,Any}[],
        :quadratic_terms => Dict{String,Any}[],
        :offset          => offset(model),
        :scale           => scale(model),
        :id              => id(model),
        :version         => version(model),
        :variable_domain => _BQPJSON_VARIABLE_DOMAIN(D),
        :variable_ids    => variables(model),
        :description     => description(model),
        :metadata        => metadata(model),
        :sampleset       => sampleset(model),
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
        "version"         => string(data[:version]),
        "variable_domain" => data[:variable_domain],
        "linear_terms"    => data[:linear_terms],
        "quadratic_terms" => data[:quadratic_terms],
        "variable_ids"    => data[:variable_ids],
        "offset"          => data[:offset],
        "scale"           => data[:scale],
        "metadata"        => data[:metadata],
    )

    if !isnothing(data[:description])
        json_data["description"] = data[:description]
    end

    if !isnothing(data[:sampleset])
        id = 0

        solutions = Dict{String,Any}[]

        for s in data[:sampleset]
            assignment = Dict{String,Any}[
                Dict{String,Any}(
                    "id"    => i,
                    "value" => state(s, j)
                ) for (i, j) in variable_map(model)
            ]

            for _ = 1:reads(s)
                push!(
                    solutions,
                    Dict{String,Any}(
                        "id"         => (id += 1),
                        "assignment" => assignment,
                        "evaluation" => value(sample),
                    )
                )
            end
        end

        data["solutions"] = solutions
    end

    JSON.print(io, data)

    return nothing
end