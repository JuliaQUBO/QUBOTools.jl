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
    domain::Union{Domain,Nothing}

    MiniZinc(domain::Union{Symbol,Domain}) = new(Domain(domain))
    MiniZinc(domain::Nothing = nothing)    = new(domain)
end

domain(fmt::MiniZinc) = fmt.domain

supports_domain(::Type{MiniZinc}, ::Val{BoolDomain}) = true
supports_domain(::Type{MiniZinc}, ::Val{SpinDomain}) = true

infer_format(::Val{:mzn})               = MiniZinc()
infer_format(::Val{:spin}, ::Val{:mzn}) = MiniZinc(SpinDomain)
infer_format(::Val{:bool}, ::Val{:mzn}) = MiniZinc(BoolDomain)

include("parser.jl")
include("printer.jl")