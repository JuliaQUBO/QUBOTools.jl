# ~*~ I/O ~*~ #
function Base.read(::IO, M::Type{<:AbstractBQPModel})
    throw(BQPCodecError("'Base.read' not implemented for model of type '$(M)'"))
end

function Base.read(path::AbstractString, M::Type{<:AbstractBQPModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(::IO, model::AbstractBQPModel)
    throw(BQPCodecError("'Base.write' not implemented for model of type '$(typeof(model))'"))
end

function Base.write(path::AbstractString, model::AbstractBQPModel)
    open(path, "w") do io
        return write(io, model)
    end
end

function Base.convert(M::Type{<:AbstractBQPModel}, model::AbstractBQPModel)
    throw(BQPCodecError("'Base.convert' not implemented for turning model of type '$(typeof(model))' into $(M)"))
end

function Base.convert(::Type{M}, model::M) where {M <: AbstractBQPModel}
    model # Short-circuit! Yeah!
end