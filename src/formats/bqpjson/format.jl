const _BQPJSON_SCHEMA_PATH    = joinpath(@__DIR__, "bqpjson.schema.json")
const _BQPJSON_SCHEMA         = JSONSchema.Schema(JSON.parsefile(_BQPJSON_SCHEMA_PATH))
const _BQPJSON_VERSION_LIST   = VersionNumber[v"1.0.0"]
const _BQPJSON_VERSION_LATEST = _BQPJSON_VERSION_LIST[end]

_BQPJSON_VARIABLE_DOMAIN(::Type{BoolDomain}) = "boolean"
_BQPJSON_VARIABLE_DOMAIN(::Type{SpinDomain}) = "spin"

_BQPJSON_VALIDATE_DOMAIN(x::Integer, ::Type{BoolDomain}) = (x == 0) || (x == 1)
_BQPJSON_VALIDATE_DOMAIN(s::Integer, ::Type{SpinDomain}) = (s == ↑) || (s == ↓)

@doc raw"""
    BQPJSON

Precise and detailed information found in the [bqpjson docs](https://bqpjson.readthedocs.io)
""" struct BQPJSON <: AbstractFormat
    domain::Union{Domain,Nothing}

    BQPJSON(domain::Union{Symbol,Domain}) = new(Domain(domain))

    function BQPJSON(
        dom::Union{Domain,Symbol,Nothing} = nothing,
        sty::Union{Style,Symbol,Nothing}  = nothing,
    )
        assert_supports_domain(BQPJSON, dom)
        assert_supports_style(BQPJSON, sty)

        return new(dom)
    end
end

domain(fmt::BQPJSON) = fmt.domain

supports_domain(::Type{BQPJSON}, ::BoolDomain) = true
supports_domain(::Type{BQPJSON}, ::SpinDomain) = true

infer_format(::Val{:json})               = BQPJSON()
infer_format(::Val{:bool}, ::Val{:json}) = BQPJSON(BoolDomain)
infer_format(::Val{:spin}, ::Val{:json}) = BQPJSON(SpinDomain)


include("parser.jl")
include("printer.jl")