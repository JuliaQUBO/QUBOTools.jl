@doc raw"""
""" abstract type AbstractFormat{D<:VariableDomain} end

@doc raw"""
    infer_format(::AbstractString)
    infer_format(::Symbol)
""" function infer_format end

function infer_format(path::String)
    ext = last(splitext(path))

    if isempty(ext)
        format_error("Unable to infer model type since file extension is missing")
    else
        # Remove '.' from the start:
        ext_sym = Symbol(ext[2:end])

        return infer_format(ext_sym)
    end
end

infer_format(ext::Symbol) = infer_format(Val(ext))

function infer_format(::Val{ext}) where {ext}
    format_error("Unable to infer model type from unknown extension '$ext'")
end


@doc raw"""
    read_model(::AbstractString, ::AbstractFormat)
    read_model(::AbstractString)
""" function read_model end

function read_model(path::AbstractString, fmt::AbstractFormat = infer_format(path))
    return open(path, "r") do fp
        return read_model(fp, fmt)
    end
end

@doc raw"""
""" function read_model! end

@doc raw"""
    write_model(::AbstractString, ::AbstractModel)
    write_model(::AbstractString, ::AbstractModel, ::AbstractFormat)
    write_model(::IO, ::AbstractModel, ::AbstractFormat)

""" function write_model end

function write_model(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = infer_format(path))
    open(path, "w") do fp
        write_model(fp, model, fmt)
    end
end