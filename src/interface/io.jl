# ~*~ I/O ~*~ #
function Base.read(::IO, M::Type{<:AbstractQUBOModel})
    QUBOcodec_error("'Base.read' not implemented for model of type '$(M)'")
end

function Base.read(path::AbstractString, M::Type{<:AbstractQUBOModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(::IO, model::AbstractQUBOModel)
    QUBOcodec_error("'Base.write' not implemented for model of type '$(typeof(model))'")
end

function Base.write(path::AbstractString, model::AbstractQUBOModel)
    open(path, "w") do io
        return write(io, model)
    end
end

function Base.convert(M::Type{<:AbstractQUBOModel}, model::AbstractQUBOModel)
    QUBOcodec_error("'Base.convert' not implemented for turning model of type '$(typeof(model))' into $(M)")
end

function Base.convert(::Type{M}, model::M) where {M<:AbstractQUBOModel}
    model # Short-circuit! Yeah!
end

function Base.show(io::IO, model::AbstractQUBOModel)
    print(
        io,
        """
        $(QUBOTools.model_name(model)) Model:
        $(QUBOTools.domain_size(model)) variables [$(QUBOTools.domain_name(model))]

        Density:
        linear    ~ $(@sprintf("%0.2f", 100.0 * QUBOTools.linear_density(model)))%
        quadratic ~ $(@sprintf("%0.2f", 100.0 * QUBOTools.quadratic_density(model)))%
        total     ~ $(@sprintf("%0.2f", 100.0 * QUBOTools.density(model)))%
        """
    )
end

function Base.copy!(::M, ::M) where {M<:AbstractQUBOModel}
    QUBOcodec_error("'Base.copy!' not implemented for copying '$M' models in-place")
end

function Base.copy!(
    target::X,
    source::Y,
) where {X<:AbstractQUBOModel,Y<:AbstractQUBOModel}
    copy!(target, convert(typeof(target), source))
end