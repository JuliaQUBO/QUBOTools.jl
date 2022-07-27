const BQPJSON_SCHEMA = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "bqpjson.schema.json")))
const BQPJSON_VERSION_LIST = VersionNumber[v"1.0.0"]
const BQPJSON_VERSION_LATEST = BQPJSON_VERSION_LIST[end]
const BQPJSON_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

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
""" mutable struct BQPJSON{D<:VariableDomain} <: AbstractBQPModel{D}
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

function isvalidbridge(
    source::BQPJSON{B},
    target::BQPJSON{B},
    ::Type{<:BQPJSON{A}};
    kws...
) where {A,B}
    flag = true

    if BQPIO.id(source) != BQPIO.id(target)
        @error "Test Failure: ID mismatch"
        flag = false
    end

    if BQPIO.version(source) != BQPIO.version(target)
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

    if !BQPIO.isvalidbridge(
        source.backend,
        target.backend;
        kws...
    )
        flag = false
    end

    return flag
end