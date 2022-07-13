# ~*~ I/O ~*~ #
function Base.read(::IO, M::Type{<:AbstractBQPModel})
    error("'Base.read' not implemented for model of type '$(M)'")
end

function Base.read(path::AbstractString, M::Type{<:AbstractBQPModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(::IO, model::AbstractBQPModel)
    error("'Base.write' not implemented for model of type '$(typeof(model))'")
end

function Base.write(path::AbstractString, model::AbstractBQPModel)
    open(path, "w") do io
        return write(io, model)
    end
end

function Base.convert(M::Type{<:AbstractBQPModel}, model::AbstractBQPModel)
    error("'Base.convert' not implemented for turning model of type '$(typeof(model))' into $(M)")
end

function Base.convert(::Type{M}, model::M) where {M <: AbstractBQPModel}
    model # Short-circuit! Yeah!
end