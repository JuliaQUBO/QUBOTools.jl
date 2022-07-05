const BQPJSON_SCHEMA = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "bqpjson.schema.json")))
const BQPJSON_VERSION_LATEST = v"1.0.0"

@doc raw"""
""" struct BQPJSON{D <: VariableDomain} <: AbstractBQPModel{D}
    id::Int
    version::VersionNumber
    variable_ids::Set{Int}
    variable_domain::String
    scale::Float64
    offset::Float64
    terms::Dict{Tuple{Int, Int}, Float64}
    metadata::Dict{String, Any}
    description::Union{String, Nothing}
    solutions::Union{Vector{Dict{String, Any}}, Nothing}

    function BQPJSON{D}(
            id::Integer,
            version::VersionNumber,
            variable_ids::Set{Int},
            variable_domain::String,
            scale::Float64,
            offset::Float64,
            terms::Dict{Tuple{Int, Int}, Float64},
            metadata::Dict{String, Any},
            description::Union{String, Nothing},
            solutions::Union{Vector{<:Any}, Nothing},
        ) where D <: VariableDomain
        model = new{D}(
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
        if isvalid(model)
            model
        else
            error("Invalid AbstractBQPModel")
        end
    end

    function BQPJSON(
            id::Integer,
            version::VersionNumber,
            variable_ids::Set{Int},
            variable_domain::String,
            scale::Float64,
            offset::Float64,
            terms::Dict{Tuple{Int, Int}, Float64},
            metadata::Dict{String, Any},
            description::Union{String, Nothing},
            solutions::Union{Vector{<:Any}, Nothing},
        )
        D = if variable_domain == "boolean"
            BoolDomain
        elseif variable_domain == "spin"
            SpinDomain
        else
            error("'variable_domain' must be either 'boolean' or 'spin'")
        end

        BQPJSON{D}(
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

    function BQPJSON{D}(data::Dict{String, Any}) where D <: VariableDomain
        if !isnothing(JSONSchema.validate(BQPJSON_SCHEMA, data))
            error("Invalid data")
        end

        id              = data["id"]
        version         = VersionNumber(data["version"])
        variable_ids    = Set{Int}(data["variable_ids"])
        variable_domain = data["variable_domain"]
        scale           = data["scale"]
        offset          = data["offset"]
        terms           = Dict{Tuple{Int, Int}, Float64}()
        metadata        = deepcopy(data["metadata"])
        description     = if haskey(data, "description")
            data["description"]
        else
            nothing
        end
        solutions       = if haskey(data, "solutions")
            deepcopy(data["solutions"])
        else
            nothing
        end

        for lt in data["linear_terms"]
            i = lt["id"]
            l = lt["coeff"]
            terms[(i, i)] = get(terms, (i, i), 0.0) + l
        end

        for qt in data["quadratic_terms"]
            i = qt["id_head"]
            j = qt["id_tail"]
            q = qt["coeff"]
            
            if j < i # swap variables
                i, j = j, i
            end

            terms[(i, j)] = get(terms, (i, j), 0.0) + q
        end

        BQPJSON{D}(
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

    function BQPJSON(data::Dict{String, Any})
        if !haskey(data, "variable_domain")
            error("Invalid data")
        end

        D = if data["variable_domain"] == "boolean"
            BoolDomain
        elseif data["variable_domain"] == "spin"
            SpinDomain
        else
            error("'variable_domain' must be either 'boolean' or 'spin'")
        end

        BQPJSON{D}(data)
    end
end

function Base.isapprox(x::BQPJSON{D}, y::BQPJSON{D}; kw...) where D <: VariableDomain
    isapprox(x.scale , y.scale ; kw...) &&
    isapprox(x.offset, y.offset; kw...) &&
    isapprox_dict(x.terms, y.terms; kw...)
end

function Base.:(==)(x::BQPJSON{D}, y::BQPJSON{D}) where D <: VariableDomain
    x.id           == y.id           &&
    x.version      == y.version      &&
    x.variable_ids == y.variable_ids &&
    x.scale        == y.scale        &&
    x.offset       == y.offset       &&
    x.terms        == y.terms        &&
    x.metadata     == y.metadata     &&
    x.description  == y.description  &&
    x.solutions    == y.solutions
end

function Base.read(io::IO, M::Type{<:BQPJSON})
    model = BQPJSON(JSON.parse(io))

    if (model isa M)
        model
    else
        convert(M, model)
    end
end

function Base.write(io::IO, model::BQPJSON)
    linear_terms    = Dict{String, Any}[]
    quadratic_terms = Dict{String, Any}[]

    for ((i, j), q) in model.terms
        if (i == j)
            push!(
                linear_terms,
                Dict{String, Any}(
                    "id"    => i,
                    "coeff" => q,
                )
            )
        else
            push!(
                quadratic_terms,
                Dict{String, Any}(
                    "id_head" => i,
                    "id_tail" => j,
                    "coeff"   => q,
                )
            )
        end
    end

    sort!(linear_terms   ; by=(lt) -> lt["id"])
    sort!(quadratic_terms; by=(qt) -> (qt["id_head"], qt["id_tail"]))

    data = Dict{String, Any}(
        "id"              => model.id,
        "version"         => string(model.version),
        "variable_ids"    => sort(collect(model.variable_ids)),
        "variable_domain" => model.variable_domain,
        "scale"           => model.scale,
        "offset"          => model.offset,
        "linear_terms"    => linear_terms,
        "quadratic_terms" => quadratic_terms,
        "metadata"        => model.metadata,
    )

    if !isnothing(model.description)
        data["description"] = model.description
    end

    if !isnothing(model.solutions)
        data["solutions"] = model.solutions
    end

    JSON.print(io, data)
end

function Base.isvalid(model::BQPJSON{D}) where D
    if model.version !== BQPJSON_VERSION_LATEST
        @error "Invalid BQPJSON version"
        return false
    end

    spin_var_domain = (model.variable_domain == "spin"    && D <: SpinDomain)
    bool_var_domain = (model.variable_domain == "boolean" && D <: BoolDomain)

    if !spin_var_domain && !bool_var_domain
        @error "Variable domain inconsistency"
        return false
    end

    if model.scale < 0.0
        @error "Negative problem scaling"
        return false
    end

    for (i, j) in keys(model.terms)
        if i == j # linear
            if i ∉ model.variable_ids
                @error "Invalid variable id '$i'"
                return false
            end
        else # quadratic
            if i ∉ model.variable_ids || j ∉ model.variable_ids || j < i
                @error "Invalid variable id or variable pair '$i, $j'"
                return false
            end
        end
    end

    if !isnothing(model.solutions)
        solution_ids = Set{Int}()

        for solution in model.solutions
            if solution["id"] ∈ solution_ids
                @error "Duplicate solution id"
                return false
            end

            push!(solution_ids, solution["id"])

            sol_var_ids = Set{Int}()

            for assign in solution["assignment"]
                var_id = assign["id"]
                value  = assign["value"]

                if var_id ∉ model.variable_ids || var_id ∈ sol_var_ids
                    @error "Invalid or duplicate variable id"
                    return false
                end

                if spin_var_domain && !(value == -1 || value == 1)
                    @error "Invalid assignment for spin variable"
                    return false
                end

                if bool_var_domain && !(value == 0  || value == 1)
                    @error "Invalid assignment for boolean variable"
                    return false
                end

                push!(sol_var_ids, var_id)
            end

            if length(sol_var_ids) != length(model.variable_ids)
                @error "Length mismach between variable set and solution assignment"
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
    id           = model.id
    version      = model.version
    variable_ids = copy(model.variable_ids)
    scale        = model.scale
    offset       = model.offset
    terms        = Dict{Tuple{Int, Int}, Float64}()
    metadata     = deepcopy(model.metadata)
    description  = model.description
    solutions    = deepcopy(model.solutions)

    for ((i, j), a) in model.terms
        if i == j # linear
            terms[(i, i)] = get(terms, (i, i), 0.0) + 2.0 * a
            offset -= a
        else # quadratic
            terms[(i, j)] = get(terms, (i, j), 0.0) + 4.0 * a
            terms[(i, i)] = get(terms, (i, i), 0.0) - 2.0 * a
            terms[(j, j)] = get(terms, (j, j), 0.0) - 2.0 * a
            offset += a
        end
    end

    if !isnothing(solutions)
        for solution in solutions
            for assign in solution["assignment"]
                assign["value"] = assign["value"] == 1 ? 1 : 0
            end
        end
    end

    BQPJSON{BoolDomain}(
        id,
        version,
        variable_ids,
        "boolean",
        scale,
        offset,
        terms,
        metadata,
        description,
        solutions,
    )
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::BQPJSON{BoolDomain})
    id           = model.id
    version      = model.version
    variable_ids = copy(model.variable_ids)
    scale        = model.scale
    offset       = model.offset
    terms        = Dict{Tuple{Int, Int}, Float64}()
    metadata     = deepcopy(model.metadata)
    description  = model.description
    solutions    = deepcopy(model.solutions)

    for ((i, j), a) in model.terms
        if i == j # linear
            terms[(i, i)] = get(terms, (i, i), 0.0) + a / 2.0
            offset += a / 2.0
        else # quadratic
            terms[(i, j)] = get(terms, (i, j), 0.0) + a / 4.0
            terms[(i, i)] = get(terms, (i, i), 0.0) + a / 4.0
            terms[(j, j)] = get(terms, (j, j), 0.0) + a / 4.0
            offset += a / 4.0
        end
    end

    if !isnothing(solutions)
        for solution in solutions
            for assign in solution["assignment"]
                assign["value"] = assign["value"] == 1 ? 1 : -1
            end
        end
    end

    BQPJSON{SpinDomain}(
        id,
        version,
        variable_ids,
        "spin",
        scale,
        offset,
        terms,
        metadata,
        description,
        solutions,
    )
end