const BQPJSON_SCHEMA          = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "bqpjson.schema.json")))
const BQPJSON_VERSION_LIST    = VersionNumber[v"1.0.0"]
const BQPJSON_VERSION_LATEST  = BQPJSON_VERSION_LIST[end]

_BQPJSON_VARIABLE_DOMAIN(::Type{𝔹}) = "boolean"
_BQPJSON_VARIABLE_DOMAIN(::Type{𝕊}) = "spin"

_BQPJSON_VALIDATE_DOMAIN(x::Integer, ::Type{𝔹}) = x ==  0 || x == 1
_BQPJSON_VALIDATE_DOMAIN(s::Integer, ::Type{𝕊}) = s == -1 || s == 1

_BQPJSON_SWAP_DOMAIN(x::Integer, ::Type{𝔹}) = (x == 1 ? 1 : -1)
_BQPJSON_SWAP_DOMAIN(s::Integer, ::Type{𝕊}) = (s == 1 ? 1 :  0)

@doc raw"""
    BQPJSON{D}() where {D<:VariableDomain}

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
""" struct BQPJSON{D} <: AbstractFormat{D} end

infer_format(::Val{:bool}, ::Val{:json}) = BQPJSON{𝔹}()
infer_format(::Val{:spin}, ::Val{:json}) = BQPJSON{𝕊}()

include("parser.jl")
include("printer.jl")