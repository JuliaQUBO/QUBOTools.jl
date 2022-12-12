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

function read_model!(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = infer_format(path))
    return open(path, "r") do fp
        return read_model!(fp, model, fmt)
    end
end

function read_model!(io::IO, model::AbstractModel, fmt::AbstractFormat)
    return copy!(model, read_model(io, fmt))
end

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

function write_model(io::IO, model::AbstractModel{X}, fmt::AbstractFormat{Y}) where {X,Y}
    return write_model(io, swap_domain(X(), Y(), model), fmt)
end