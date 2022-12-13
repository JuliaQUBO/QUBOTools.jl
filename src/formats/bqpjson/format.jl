const BPQJSON_SCHEMA_PATH     = joinpath(@__DIR__, "bqpjson.schema.json")
const BQPJSON_SCHEMA          = JSONSchema.Schema(JSON.parsefile(BQPJSON_SCHEMA_PATH))
const BQPJSON_VERSION_LIST    = VersionNumber[v"1.0.0"]
const BQPJSON_VERSION_LATEST  = BQPJSON_VERSION_LIST[end]

_BQPJSON_VARIABLE_DOMAIN(::Type{𝔹}) = "boolean"
_BQPJSON_VARIABLE_DOMAIN(::Type{𝕊}) = "spin"

@doc raw"""
    BQPJSON{D}() where {D<:VariableDomain}

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
""" struct BQPJSON{D} <: AbstractFormat{D} end

infer_format(::Val{:bool}, ::Val{:json}) = BQPJSON{𝔹}()
infer_format(::Val{:spin}, ::Val{:json}) = BQPJSON{𝕊}()

include("parser.jl")
include("printer.jl")