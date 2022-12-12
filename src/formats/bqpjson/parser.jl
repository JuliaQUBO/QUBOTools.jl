function _parse_version!(::BQPJSON, data::Dict{Symbol,Any}, json_data::Dict{String,Any})
    bqpjson_version = VersionNumber(json_data["version"])

    if bqpjson_version !== BQPJSON_VERSION_LATEST
        codec_error("Outdated BQPJSON version '$bqpjson_version'")
    end

    data[:version] = bqpjson_version

    return nothing
end

function _parse_domain!(::BQPJSON, data::Dict{Symbol,Any}, json_data::Dict{String,Any})
    bqpjson_domain = json_data["variable_domain"]

    if bqpjson_domain == "boolean"
        data[:domain] = BoolDomain
    elseif bqpjson_domain == "spin"
        data[:domain] = SpinDomain
    else
        codec_error("Inconsistent variable domain '$variable_domain'")
    end

    return nothing
end

function _parse_terms!(::BQPJSON, data::Dict{Symbol,Any}, json_data::Dict{String,Any})
    # Variables
    V = data[:variable_set]

    # Linear terms
    L = data[:linear_terms]

    for lt in json_data["linear_terms"]
        i = lt["id"]
        c = lt["coeff"]

        if i ∉ V
            format_error("Unknown variable id '$i'")
        end

        L[i] = get(L, i, 0.0) + c
    end

    # Quadratic terms
    Q = data[:quadratic_terms]

    for qt in json_data["quadratic_terms"]
        i = qt["id_head"]
        j = qt["id_tail"]
        c = qt["coeff"]

        if i == j
            format_error("Twin quadratic term '$i, $j'")
        elseif i ∉ V
            format_error("Unknown variable id '$i'")
        elseif j ∉ V
            format_error("Unknown variable id '$j'")
        elseif j ≺ i
            i, j = j, i
        end

        Q[(i, j)] = get(Q, (i, j), 0.0) + c
    end

    return nothing
end

function _parse_solutions!(::BQPJSON, data::Dict{Symbol,Any}, json_data::Dict{String,Any})
    solutions = get(data, "solutions", nothing)

    if isnothing(solutions)
        data[:sampleset] = nothing

        return nothing
    end

    samples           = Sample{Float64,Int}[]
    sultion_ids       = Set{Int}()
    solution_metadata = Dict{String,Any}()

    for solution in json_data["solutions"]
        i = solution["id"]

        if i ∈ sultion_ids
            format_error("Invalid data: Duplicate solution id '$i'")
        else
            push!(sultion_ids, i)
        end

        var_ids = Set{Int}()

        for assign in solution["assignment"]
            j = assign["id"]
            v = assign["value"]

            if j ∉ data[:variable_set]
                format_error("Unknown variable id '$j' in assignment")
            elseif j ∈ var_ids
                format_error("Duplicate variable id '$j' in assignment")
            elseif !BQPJSON_VALIDATE_DOMAIN(v, data[:domain])
                format_error("Variable assignment '$v' out of domain")
            end

            push!(var_ids, j)
        end

        if length(var_ids) != length(data[:variable_set])
            format_error("Length mismatch between variable set and solution assignment")
        end
    end

    data[:sampleset] = SampleSet{Float64,Int}(samples)

    return nothing
end

function read_model(io::IO, fmt::BQPJSON{D}) where {D}
    json_data = JSON.parse(io)
    report    = JSONSchema.validate(BQPJSON_SCHEMA, json_data)
    
    if !isnothing(report)
        codec_error("Schema violation:\n$(report)")
    end
    
    data = Dict{Symbol,Any}(
        :id               => json_data["id"],
        :scale            => json_data["scale"],
        :offset           => json_data["offset"],
        :variable_set     => Set{Int}(json_data["variable_ids"]),
        :linear_terms     => Dict{Int,Float64}(),
        :quadratic_terms  => Dict{Tuple{Int,Int},Float64}(),
        :description      => get(json_data, "description", nothing),
        :metadata         => deepcopy(json_data["metadata"]),
    )

    _parse_version!(fmt, data, json_data)
    _parse_domain!(fmt, data, json_data)
    _parse_terms!(fmt, data, json_data)
    _parse_solutions!(fmt, data, json_data)

    model = StandardModel{data[:domain]}(
        data[:linear_terms],
        data[:quadratic_terms];
        scale       = data[:scale],
        offset      = data[:offset],
        id          = data[:id],
        version     = data[:version],
        description = data[:description],
        metadata    = data[:metadata],
        sampleset   = data[:sampleset],
    )

    return convert(StandardModel{D}, model)
end

