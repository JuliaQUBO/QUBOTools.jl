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
""" struct MiniZinc{D} <: AbstractFormat{D} end

infer_format(::Val{:mzn})               = MiniZinc{UnknownDomain}()
infer_format(::Val{:spin}, ::Val{:mzn}) = MiniZinc{SpinDomain}()
infer_format(::Val{:bool}, ::Val{:mzn}) = MiniZinc{BoolDomain}()

include("parser.jl")
include("printer.jl")