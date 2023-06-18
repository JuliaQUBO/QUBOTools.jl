function format(path::AbstractString)
    pieces = Symbol.(reverse(split(basename(path), ".")))

    if length(pieces) == 1
        format_error("Unable to infer QUBO format from file without an extension")
    else
        # Get two last fragments of the file name
        format_hint, extra_hint = first(pieces, 2)

        return format(extra_hint, format_hint)
    end
end

function format(extra_hint::Symbol, format_hint::Symbol)
    return format(Val(extra_hint), Val(format_hint))
end

function format(::Val, format_hint::Val)
    return format(format_hint)
end

function format(format_hint::Symbol)
    return format(Val(format_hint))
end
