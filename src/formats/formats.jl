include("error.jl")
include("interface.jl")

# ~ Supported Formats ~ #
include("bqpjson/format.jl")
include("hfs/format.jl")
include("minizinc/format.jl")
include("qubist/format.jl")
include("qubo/format.jl")

function domains()
    return Type[dom for dom in subtypes(VariableDomain) if dom !== UnknownDomain]
end

function formats()
    domain_list = domains()
    format_list = subtypes(AbstractFormat)

    return Type[fmt{dom} for dom in domain_list, fmt in format_list if (fmt{<:dom} <: fmt)]
end

function infer_format(path::AbstractString)
    pieces = reverse(split(basename(path), "."))

    if length(pieces) == 1
        format_error("Unable to infer QUBO format from file without an extension")
    else
        format_hint, domain_hint, _... = pieces
    end

    return infer_format(Symbol(domain_hint), Symbol(format_hint))
end

function infer_format(domain_hint::Symbol, format_hint::Symbol)
    return infer_format(Val(domain_hint), Val(format_hint))
end

function infer_format(::Val, format_hint::Val)
    return infer_format(format_hint)
end

function infer_format(format_hint::Symbol)
    return infer_format(Val(format_hint))
end