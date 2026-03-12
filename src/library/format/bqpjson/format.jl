const _BQPJSON_SCHEMA_PATH    = joinpath(@__DIR__, "bqpjson.schema.json")
const _BQPJSON_SCHEMA         = JSONSchema.Schema(JSON.parsefile(_BQPJSON_SCHEMA_PATH))
const _BQPJSON_VERSION_LIST   = VersionNumber[v"1.0.0"]
const _BQPJSON_VERSION_LATEST = _BQPJSON_VERSION_LIST[end]

function _BQPJSON_VARIABLE_DOMAIN(X::Domain)
    if X === QUBOTools.BoolDomain
        return "boolean"
    elseif X === QUBOTools.SpinDomain
        return "spin"
    else
        error("Invalid domain '$X'")
    end
end

function _BQPJSON_VALIDATE_DOMAIN(x::Integer, X::Domain)
    if X === QUBOTools.BoolDomain
        return (x == 0) || (x == 1)
    elseif X === QUBOTools.SpinDomain
        return (x == ↓) || (x == ↑)
    else
        error("Invalid domain '$X'")
    end
end

@doc raw"""
    Format{:bqpjson}(; version::VersionNumber, indent::Integer)

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
"""
const bqpjson_fmt = Format{:bqpjson}

function Format{:bqpjson}(; version::VersionNumber = _BQPJSON_VERSION_LATEST, indent::Integer = 2)
    @assert version ∈ _BQPJSON_VERSION_LIST
    @assert indent >= 0

    return Format{:bqpjson}(
        Dict{Symbol,Any}(
            :version => version,
            :indent  => indent,
        )
    )
end

infer_format(::Val{:json}) = Format{:bqpjson}()

include("parser.jl")
include("printer.jl")
