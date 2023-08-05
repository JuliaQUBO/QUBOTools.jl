const _BQPJSON_SCHEMA_PATH    = joinpath(@__DIR__, "bqpjson.schema.json")
const _BQPJSON_SCHEMA         = JSONSchema.Schema(JSON.parsefile(_BQPJSON_SCHEMA_PATH))
const _BQPJSON_VERSION_LIST   = VersionNumber[v"1.0.0"]
const _BQPJSON_VERSION_LATEST = _BQPJSON_VERSION_LIST[end]

function _BQPJSON_VARIABLE_DOMAIN(X::Domain)
    if X === 𝔹
        return "boolean"
    elseif X === 𝕊
        return "spin"
    else
        error("Invalid domain '$X'")
    end
end

function _BQPJSON_VALIDATE_DOMAIN(x::Integer, X::Domain)
    if X === 𝔹
        return (x == 0) || (x == 1)
    elseif X === 𝕊
        return (s == ↑) || (s == ↓)
    else
        error("Invalid domain '$X'")
    end
end

@doc raw"""
    BQPJSON(X::Union{Domain,Nothing}; indent::Integer)

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
"""
struct BQPJSON{S} <: AbstractFormat{S}
    domain::Union{Domain,Nothing}
    version::VersionNumber
    indent::Int

    function BQPJSON(
        domain::Union{Domain,Nothing} = nothing;
        version::VersionNumber        = v"1.0.0",
        indent::Integer               = 2,
    )
        @assert version ∈ _BQPJSON_VERSION_LIST
        @assert indent >= 0

        return new{nothing}(domain, version, indent)
    end
end

domain(fmt::BQPJSON) = fmt.domain

format(::Val{:bool}, ::Val{:json}) = BQPJSON(𝔹)
format(::Val{:spin}, ::Val{:json}) = BQPJSON(𝕊)
format(::Val{:json})               = BQPJSON()

include("parser.jl")
include("printer.jl")
