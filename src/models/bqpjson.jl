const BQPJSON_SCHEMA = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "bqpjson.schema.json")))
const BQPJSON_VERSION_LIST = VersionNumber[v"1.0.0"]
const BQPJSON_VERSION_LATEST = BQPJSON_VERSION_LIST[end]
const BQPJSON_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

function BQPJSON_DEFAULT_OFFSET end
BQPJSON_DEFAULT_OFFSET(::Nothing) = 0.0
BQPJSON_DEFAULT_OFFSET(offset::Float64) = offset

function BQPJSON_DEFAULT_SCALE end
BQPJSON_DEFAULT_SCALE(::Nothing) = 1.0
BQPJSON_DEFAULT_SCALE(scale::Float64) = scale

function BQPJSON_DEFAULT_ID end
BQPJSON_DEFAULT_ID(::Nothing) = 0
BQPJSON_DEFAULT_ID(id::Integer) = id

function BQPJSON_DEFAULT_VERSION end
BQPJSON_DEFAULT_VERSION(::Nothing) = string(BQPJSON_VERSION_LATEST)
BQPJSON_DEFAULT_VERSION(version::VersionNumber) = string(version)

function BQPJSON_DEFAULT_METADATA end
BQPJSON_DEFAULT_METADATA(::Nothing) = Dict{String,Any}()
BQPJSON_DEFAULT_METADATA(metadata::Dict{String,Any}) = deepcopy(metadata)

function BQPJSON_VARIABLE_DOMAIN end
BQPJSON_VARIABLE_DOMAIN(::Type{<:BoolDomain}) = "boolean"
BQPJSON_VARIABLE_DOMAIN(::Type{<:SpinDomain}) = "spin"

function BQPJSON_VALIDATE_DOMAIN end
BQPJSON_VALIDATE_DOMAIN(x::Integer, ::Type{<:BoolDomain}) = x == 0 || x == 1
BQPJSON_VALIDATE_DOMAIN(s::Integer, ::Type{<:SpinDomain}) = s == -1 || s == 1

function BQPJSON_SWAP_DOMAIN end
BQPJSON_SWAP_DOMAIN(x::Integer, ::Type{<:BoolDomain}) = (x == 1 ? 1 : -1)
BQPJSON_SWAP_DOMAIN(s::Integer, ::Type{<:SpinDomain}) = (s == 1 ? 1 : 0)

@doc raw"""
    BQPJSON{D}(
        backend::BQPJSON_BACKEND_TYPE{D},
        solutions::Union{Vector,Nothing},
    ) where {D<:VariableDomain}

### References
[1] https://bqpjson.readthedocs.io
""" struct BQPJSON{D<:VariableDomain} <: AbstractBQPModel{D}
    backend::BQPJSON_BACKEND_TYPE{D}
    solutions::Union{Vector,Nothing}

    function BQPJSON{D}(
        backend::BQPJSON_BACKEND_TYPE{D},
        solutions::Union{Vector,Nothing},
    ) where {D<:VariableDomain}
        new{D}(backend, solutions)
    end

    function BQPJSON{D}(
        linear_terms::Dict{Int,Float64},
        quadratic_terms::Dict{Tuple{Int,Int},Float64},
        variable_map::Dict{Int,Int},
        offset::Float64,
        scale::Float64,
        id::Integer,
        version::VersionNumber,
        description::Union{String,Nothing},
        metadata::Dict{String,Any},
        solutions::Union{Vector,Nothing},
    ) where {D<:VariableDomain}
        backend = BQPJSON_BACKEND_TYPE{D}(
            # ~*~ Required data ~*~
            linear_terms,
            quadratic_terms,
            variable_map;
            # ~*~ Factors ~*~
            offset=offset,
            scale=scale,
            # ~*~ Metadata ~*~
            id=id,
            version=version,
            description=description,
            metadata=metadata
        )

        BQPJSON{D}(backend, solutions)
    end
end

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
    backend = model.backend
    linear_terms = Dict{String,Any}[]
    quadratic_terms = Dict{String,Any}[]
    offset = BQPJSON_DEFAULT_OFFSET(backend.offset)
    scale = BQPJSON_DEFAULT_SCALE(backend.scale)
    id = BQPJSON_DEFAULT_ID(backend.id)
    version = BQPJSON_DEFAULT_VERSION(backend.version)
    variable_domain = BQPJSON_VARIABLE_DOMAIN(D)
    metadata = BQPJSON_DEFAULT_METADATA(backend.metadata)

    for (i, l) in backend.linear_terms
        push!(
            linear_terms,
            Dict{String,Any}(
                "id" => backend.variable_inv[i],
                "coeff" => l,
            )
        )
    end

    for ((i, j), q) in backend.quadratic_terms
        push!(
            quadratic_terms,
            Dict{String,Any}(
                "id_head" => backend.variable_inv[i],
                "id_tail" => backend.variable_inv[j],
                "coeff" => q,
            )
        )
    end

    sort!(linear_terms; by=(lt) -> lt["id"])
    sort!(quadratic_terms; by=(qt) -> (qt["id_head"], qt["id_tail"]))

    variable_ids = sort(collect(keys(backend.variable_map)))

    data = Dict{String,Any}(
        "id" => id,
        "version" => version,
        "variable_domain" => variable_domain,
        "linear_terms" => linear_terms,
        "quadratic_terms" => quadratic_terms,
        "variable_ids" => variable_ids,
        "offset" => offset,
        "scale" => scale,
        "metadata" => metadata,
    )

    if !isnothing(backend.description)
        data["description"] = backend.description
    end

    if !isnothing(model.solutions)
        data["solutions"] = deepcopy(model.solutions)
    elseif !isnothing(backend.sampleset)
        id = 0

        solutions = Dict{String,Any}[]

        for sample in backend.sampleset
            assignment = Dict{String,Any}[
                Dict{String,Any}(
                    "id" => i,
                    "value" => sample.state[j]
                ) for (i, j) in backend.variable_map
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

function isvalidbridge(
    source::BQPJSON{B},
    target::BQPJSON{B},
    ::Type{<:BQPJSON{A}};
    kws...
) where {A,B}
    flag = true

    if source.backend.id != target.backend.id
        @error "Test Failure: ID mismatch"
        flag = false
    end

    if source.backend.version != target.backend.version
        @error "Test Failure: Version mismatch"
        flag = false
    end

    if !isnothing(source.backend.description) && (source.backend.description != target.backend.description)
        @error "Test Failure: Description mismatch"
        flag = false
    end

    if !isempty(source.backend.metadata) && (source.backend.metadata != source.backend.metadata)
        @error "Test Failure: Inconsistent metadata"
        flag = false
    end

    if !isnothing(source.solutions) && (source.solutions != source.solutions)
        @error "Test Failure: Inconsistent solutions"
        flag = false
    end

    if !isvalidbridge(
        source.backend,
        target.backend,
        BQPJSON_BACKEND_TYPE{A};
        kws...
    )
        flag = false
    end

    return flag
end