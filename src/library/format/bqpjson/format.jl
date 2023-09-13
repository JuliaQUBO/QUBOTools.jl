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

        return nothing
    end
end

function _BQPJSON_VALIDATE_DOMAIN(x::Integer, X::Domain)
    if X === 𝔹
        return (x == 0) || (x == 1)
    elseif X === 𝕊
        return (s == ↓) || (s == ↑)
    else
        error("Invalid domain '$X'")

        return nothing
    end
end

@doc raw"""
    BQPJSON(; version::VersionNumber, indent::Integer)

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
"""
struct BQPJSON <: AbstractFormat
    version::VersionNumber
    indent::Int

    function BQPJSON(;
        version::VersionNumber = _BQPJSON_VERSION_LATEST,
        indent::Integer        = 2,
    )
        @assert version ∈ _BQPJSON_VERSION_LIST
        @assert indent >= 0

        return new(version, indent)
    end
end

format(::Val{:json}) = BQPJSON()

include("parser.jl")
include("printer.jl")
