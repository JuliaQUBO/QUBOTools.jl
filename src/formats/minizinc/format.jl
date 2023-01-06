const _MINIZINC_VAR_SYMBOL   = "x"
const _MINIZINC_RE_COMMENT   = r"^%(\s*.*)?$"
const _MINIZINC_RE_METADATA  = r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.+)$"
const _MINIZINC_RE_DOMAIN    = r"^set of int\s*:\s*Domain\s*=\s*\{\s*([+-]?[0-9]+)\s*,\s*([+-]?[0-9]+)\s*\}\s*;$"
const _MINIZINC_RE_FACTOR    = r"^float\s*:\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([+-]?([0-9]*[.])?[0-9]+)\s*;$"
const _MINIZINC_RE_VAR       = r"^" * _MINIZINC_VAR_SYMBOL * r"([0-9]+)$"
const _MINIZINC_RE_VAR_DEF   = r"^var\s+Domain\s*:\s*" * _MINIZINC_VAR_SYMBOL * r"([0-9]+)\s*;$"
const _MINIZINC_RE_OBJECTIVE = r"^var\s+float\s*:\s*objective\s*=\s*(.+);$"
const _MINIZINC_RE_SENSE     = r"^solve (minimize|maximize) objective;$"

@doc raw"""
""" struct MiniZinc <: AbstractFormat
    domain::Union{BoolDomain,SpinDomain,Nothing}

    function MiniZinc(
        dom::Union{BoolDomain,SpinDomain,Nothing} = nothing,
        sty::Nothing                              = nothing,
    )
        return new(dom)
    end
end

domain(fmt::MiniZinc) = fmt.domain

supports_domain(::Type{MiniZinc}, ::Nothing)    = true
supports_domain(::Type{MiniZinc}, ::BoolDomain) = true
supports_domain(::Type{MiniZinc}, ::SpinDomain) = true

infer_format(::Val{:mzn})               = MiniZinc(nothing, nothing)
infer_format(::Val{:spin}, ::Val{:mzn}) = MiniZinc(𝕊, nothing)
infer_format(::Val{:bool}, ::Val{:mzn}) = MiniZinc(𝔹, nothing)

include("parser.jl")
include("printer.jl")