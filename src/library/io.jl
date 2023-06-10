function read_model(path::AbstractString, fmt::AbstractFormat = format(path))
    return open(path, "r") do fp
        return read_model(fp, fmt)
    end
end

function write_model(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = format(path))
    return open(path, "w") do fp
        return write_model(fp, model, fmt)
    end
end
