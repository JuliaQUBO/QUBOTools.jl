const _BQPJSON_SCHEMA_PATH    = joinpath(@__DIR__, "bqpjson.schema.json")
const _BQPJSON_SCHEMA         = JSONSchema.Schema(JSON.parsefile(_BQPJSON_SCHEMA_PATH))
const _BQPJSON_VERSION_LIST   = VersionNumber[v"1.0.0"]
const _BQPJSON_VERSION_LATEST = _BQPJSON_VERSION_LIST[end]

_BQPJSON_VARIABLE_DOMAIN(::BoolDomain) = "boolean"
_BQPJSON_VARIABLE_DOMAIN(::SpinDomain) = "spin"

_BQPJSON_VALIDATE_DOMAIN(x::Integer, ::BoolDomain) = (x == 0) || (x == 1)
_BQPJSON_VALIDATE_DOMAIN(s::Integer, ::SpinDomain) = (s == ↑) || (s == ↓)

@doc raw"""
    BQPJSON

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
"""
struct BQPJSON <: AbstractFormat
    domain::Union{BoolDomain,SpinDomain,Nothing}
    indent::Int

    BQPJSON(domain::Union{Symbol,Domain}) = new(Domain(domain))

    function BQPJSON(
        dom::Union{BoolDomain,SpinDomain,Nothing} = nothing,
        sty::Nothing                              = nothing;
        indent::Integer                           = 0,
    )
        return new(dom, indent)
    end
end

domain(fmt::BQPJSON) = fmt.domain

supports_domain(::Type{BQPJSON}, ::Nothing)    = true
supports_domain(::Type{BQPJSON}, ::BoolDomain) = true
supports_domain(::Type{BQPJSON}, ::SpinDomain) = true

infer_format(::Val{:json})               = BQPJSON(nothing, nothing)
infer_format(::Val{:bool}, ::Val{:json}) = BQPJSON(𝔹, nothing)
infer_format(::Val{:spin}, ::Val{:json}) = BQPJSON(𝕊, nothing)


include("parser.jl")
include("printer.jl")
