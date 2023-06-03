function infer_format(path::AbstractString)
    pieces = Symbol.(reverse(split(basename(path), ".")))

    if length(pieces) == 1
        format_error("Unable to infer QUBO format from file without an extension")
    else
        # Get two last fragments of the file name
        format_hint, extra_hint = first(pieces, 2)
    end

    return infer_format(extra_hint, format_hint)
end

function infer_format(extra_hint::Symbol, format_hint::Symbol)
    return infer_format(Val(extra_hint), Val(format_hint))
end

function infer_format(::Val, format_hint::Val)
    return infer_format(format_hint)
end

function infer_format(format_hint::Symbol)
    return infer_format(Val(format_hint))
end