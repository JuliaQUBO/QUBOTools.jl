function style(::AbstractFormat)
    return nothing
end

function format(path::AbstractString)
    pieces = split(basename(path), ".")

    if length(pieces) <= 1
        format_error("Unable to infer QUBO format from file name without an extension")
    else
        return format(Val.(Symbol.(pieces))...)
    end
end

function format(hints::Symbol...)
    return format(Val.(hints)...)
end

function format(::Val, hints::Val...)
    return format(hints...)
end
