""" /src/abstract/data.jl @ QUBOTools.jl

    This file contains abstract implementations for data access and querying.
"""

# ~*~ Base methods ~*~ #
Base.isvalid(::AbstractQUBOModel) = true
Base.isempty(model::AbstractQUBOModel) = isempty(QUBOTools.variable_map(model))

# ~*~ Data access ~*~ #
QUBOTools.model_name(::X) where {X<:AbstractQUBOModel} = string(X)
QUBOTools.domain(::AbstractQUBOModel{D}) where {D} = D
QUBOTools.domain_name(model::AbstractQUBOModel{<:BoolDomain}) = "Bool"
QUBOTools.domain_name(model::AbstractQUBOModel{<:SpinDomain}) = "Spin"

QUBOTools.swap_domain(::Type{D}, model::AbstractQUBOModel{D}) where {D<:VariableDomain} = copy(model)

function QUBOTools.swap_domain(::Type{D}, model::M) where {D<:VariableDomain,M<:AbstractQUBOModel}
    QUBOTools.codec_error("Unable to represent model of type '$M' with '$D' variables")
end

function explicit_linear_terms(model::AbstractQUBOModel)
    return QUBOTools._explicit_linear_terms(
        QUBOTools.linear_terms(model),
        QUBOTools.variable_inv(model)
    )
end

function _explicit_linear_terms(
    linear_terms::Dict{Int,T},
    variable_inv::Dict{Int,<:Any},
) where {T}
    merge(
        Dict{Int,T}(i => zero(T) for i in keys(variable_inv)),
        linear_terms,
    )
end

function QUBOTools.variables(model::AbstractQUBOModel)
    variable_map = QUBOTools.variable_map(model)

    return sort(collect(keys(variable_map)); lt=varcmp)
end

function QUBOTools.variable_set(model::AbstractQUBOModel)
    variable_map = QUBOTools.variable_map(model)

    return Set(keys(variable_map))
end

function QUBOTools.variable_map(model::AbstractQUBOModel, v)
    variable_map = QUBOTools.variable_map(model)

    if haskey(variable_map, v)
        return variable_map[v]
    else
        error("Variable '$v' doesn't belong to the model")
    end
end

function QUBOTools.variable_inv(model::AbstractQUBOModel, i::Integer)
    variable_inv = QUBOTools.variable_inv(model)

    if haskey(variable_inv, i)
        return variable_inv[i]
    else
        error("Variable index '$i' doesn't belong to the model")
    end
end

# ~*~ Model's Normal Forms ~*~ #
QUBOTools.qubo(model::AbstractQUBOModel{<:BoolDomain}) = QUBOTools.qubo(Dict, Float64, model)

function QUBOTools.qubo(::AbstractQUBOModel{<:SpinDomain})
    QUBOTools.codec_error(
        """
        Can't generate qubo normal form from ising model.
        Consider converting your model with `convert`"""
    )
end

function QUBOTools.qubo(::Type{<:Dict}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    m = QUBOTools.domain_size(model)
    n = QUBOTools.quadratic_size(model)

    Q = Dict{Tuple{Int,Int},T}()

    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    sizehint!(Q, m + n)

    for (i, qᵢ) in QUBOTools.explicit_linear_terms(model)
        Q[i, i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (Q, α, β)
end

function QUBOTools.qubo(::Type{<:Array}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    n = QUBOTools.domain_size(model)

    Q = zeros(T, n, n)

    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, qᵢᵢ) in QUBOTools.linear_terms(model)
        Q[i, i] = qᵢᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (Q, α, β)
end

QUBOTools.ising(model::AbstractQUBOModel{<:SpinDomain}) = QUBOTools.ising(Dict, Float64, model)

function QUBOTools.ising(::AbstractQUBOModel{<:BoolDomain})
    QUBOTools.codec_error(
        """
        Can't generate ising normal form from boolean model.
        Consider converting your model with `convert`"""
    )
end

function QUBOTools.ising(::Type{<:Dict}, T::Type, model::AbstractQUBOModel{<:SpinDomain})
    m = QUBOTools.domain_size(model)
    n = QUBOTools.quadratic_size(model)

    h = Dict{Int,T}()
    J = Dict{Tuple{Int,Int},T}()

    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    sizehint!(h, m)
    sizehint!(J, n)

    for (i, qᵢ) in QUBOTools.explicit_linear_terms(model)
        h[i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        J[i, j] = qᵢⱼ
    end

    return (h, J, α, β)
end

function QUBOTools.ising(::Type{<:Array}, T::Type, model::AbstractQUBOModel{<:SpinDomain})
    n = QUBOTools.domain_size(model)

    h = zeros(T, n)
    J = zeros(T, n, n)

    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, hᵢ) in QUBOTools.linear_terms(model)
        h[i] = hᵢ
    end

    for ((i, j), Jᵢⱼ) in QUBOTools.quadratic_terms(model)
        J[i, j] = Jᵢⱼ
    end

    return (h, J, α, β)
end

# ~*~ Data queries ~*~ #
function QUBOTools.energy(state::Vector, model::AbstractQUBOModel)
    @assert length(state) == QUBOTools.domain_size(model)

    α = QUBOTools.scale(model)
    s = QUBOTools.offset(model)

    for (i, l) in QUBOTools.linear_terms(model)
        s += state[i] * l
    end

    for ((i, j), q) in QUBOTools.quadratic_terms(model)
        s += state[i] * state[j] * q
    end

    return α * s
end

# ~*~ Queries: sizes & density ~*~ #
QUBOTools.domain_size(model::AbstractQUBOModel) = length(QUBOTools.variable_map(model))
QUBOTools.linear_size(model::AbstractQUBOModel) = length(QUBOTools.linear_terms(model))
QUBOTools.quadratic_size(model::AbstractQUBOModel) = length(QUBOTools.quadratic_terms(model))

function QUBOTools.density(model::AbstractQUBOModel)
    n = QUBOTools.domain_size(model)

    if n == 0
        return NaN
    else
        l = QUBOTools.linear_size(model)
        q = QUBOTools.quadratic_size(model)

        return (2 * q + l) / (n * n)
    end
end

function QUBOTools.linear_density(model::AbstractQUBOModel)
    n = QUBOTools.domain_size(model)

    if n == 0
        return NaN
    else
        l = QUBOTools.linear_size(model)

        return l / n
    end
end

function QUBOTools.quadratic_density(model::AbstractQUBOModel)
    n = QUBOTools.domain_size(model)

    if n <= 1
        return NaN
    else
        q = QUBOTools.quadratic_size(model)

        return (2 * q) / (n * (n - 1))
    end
end

# ~*~ Internal: bridge validation ~*~ #
QUBOTools.__isvalidbridge(
    source::M,
    target::M,
    ::Type{<:AbstractQUBOModel};
    kws...
) where {M<:AbstractQUBOModel} = false

# ~*~ :: I/O :: ~*~ #
function Base.read(::IO, M::Type{<:AbstractQUBOModel})
    QUBOTools.codec_error("'Base.read' not implemented for model of type '$(M)'")
end

function Base.read(path::AbstractString, M::Type{<:AbstractQUBOModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(::IO, model::AbstractQUBOModel)
    QUBOTools.codec_error("'Base.write' not implemented for model of type '$(typeof(model))'")
end

function Base.write(path::AbstractString, model::AbstractQUBOModel)
    open(path, "w") do io
        return write(io, model)
    end
end

function Base.convert(::Type{Y}, ::X) where {X <: AbstractQUBOModel, Y<:AbstractQUBOModel}
    QUBOTools.codec_error("'Base.convert' not implemented for turning model of type '$(X)' into '$(Y)'")
end

function Base.convert(::Type{M}, model::M) where {M<:AbstractQUBOModel}
    model # Short-circuit! Yeah!
end

function Base.copy!(::M, ::M) where {M<:AbstractQUBOModel}
    QUBOTools.codec_error("'Base.copy!' not implemented for copying '$M' models in-place")
end

function Base.copy!(
    target::X,
    source::Y,
) where {X<:AbstractQUBOModel,Y<:AbstractQUBOModel}
    copy!(target, convert(X, source))
end

function Base.show(io::IO, model::AbstractQUBOModel)
    if !isempty(model)
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
    else
        print(
            io,
            """
            $(QUBOTools.model_name(model)) Model:
            $(QUBOTools.domain_size(model)) variables [$(QUBOTools.domain_name(model))]

            The model is empty
            """
        )
    end
end
