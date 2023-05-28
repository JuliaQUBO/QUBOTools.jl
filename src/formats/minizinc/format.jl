const _MINIZINC_VAR_SYMBOL   = "x"
const _MINIZINC_RE_COMMENT   = r"^%(\s*.*)?$"
const _MINIZINC_RE_METADATA  = r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.+)$"
const _MINIZINC_RE_DOMAIN    = r"^set of int\s*:\s*Domain\s*=\s*\{\s*([+-]?[0-9]+)\s*,\s*([+-]?[0-9]+)\s*\}\s*;$"
const _MINIZINC_RE_FACTOR    = r"^float\s*:\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([+-]?([0-9]*[.])?[0-9]+)\s*;$"
const _MINIZINC_RE_VAR       = r"^" * _MINIZINC_VAR_SYMBOL * r"([0-9]+)$"
const _MINIZINC_RE_VAR_DEF   = r"^var\s+Domain\s*:\s*" * _MINIZINC_VAR_SYMBOL * r"([0-9]+)\s*;$"
const _MINIZINC_RE_OBJECTIVE = r"^var\s+float\s*:\s*objective\s*=\s*(.+);$"
const _MINIZINC_RE_SENSE     = r"^solve\s(minimize|maximize)\sobjective;$"

@doc raw"""
    MiniZinc(X::Union{Domain,Nothing})
"""
struct MiniZinc{S} <: AbstractFormat{S}
    domain::Union{Domain,Nothing}

    function MiniZinc(X::Union{Domain,Nothing} = nothing)
        return new{nothing}(X)
    end
end

domain(fmt::MiniZinc) = fmt.domain

infer_format(::Val{:spin}, ::Val{:mzn}) = MiniZinc(𝕊)
infer_format(::Val{:bool}, ::Val{:mzn}) = MiniZinc(𝔹)
infer_format(::Val{:mzn})               = MiniZinc()

include("parser.jl")
include("printer.jl")
