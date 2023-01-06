function format_types()
    return subtypes(AbstractFormat)
end

function formats()
    return [
        fmt(dom, sty)
        for fmt in format_types()
        for dom in domains()
        for sty in styles()
        if supports_domain(fmt, dom) && supports_style(fmt, sty)
    ]
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