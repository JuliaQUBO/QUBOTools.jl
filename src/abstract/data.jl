Base.isvalid(::AbstractQUBOModel) = false
Base.isempty(model::AbstractQUBOModel) = (QUBOTools.domain_size(model) == 0)

QUBOTools.__isvalidbridge(
    source::M,
    target::M,
    ::Type{<:AbstractQUBOModel};
    kws...
) where {M<:AbstractQUBOModel} = false

QUBOTools.model_name(::X) where {X<:AbstractQUBOModel} = string(X)

QUBOTools.domain(::AbstractQUBOModel{D}) where {D} = D
QUBOTools.domain_name(model::AbstractQUBOModel{<:BoolDomain}) = "Bool"
QUBOTools.domain_name(model::AbstractQUBOModel{<:SpinDomain}) = "Spin"

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

QUBOTools.domain_size(model::AbstractQUBOModel) = length(QUBOTools.variable_map(model))
QUBOTools.linear_size(model::AbstractQUBOModel) = length(QUBOTools.linear_terms(model))
QUBOTools.quadratic_size(model::AbstractQUBOModel) = length(QUBOTools.quadratic_terms(model))

QUBOTools.qubo(model::AbstractQUBOModel{<:BoolDomain}) = QUBOTools.qubo(Dict, Float64, model)

function QUBOTools.qubo(::AbstractQUBOModel{<:SpinDomain})
    QUBOTools.codec_error(
        """
        Can't generate normal qubo form from ising model.
        Consider converting your model with `convert`"""
    )
end

function QUBOTools.qubo(::Type{<:Dict}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    Q = Dict{Tuple{Int,Int},T}()
    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, qᵢ) in QUBOTools.linear_terms(model)
        Q[i, i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (Q, α, β)
end

function QUBOTools.qubo(::Type{<:Array}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    n = length(x)
    Q = zeros(T, n, n)
    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, qᵢ) in QUBOTools.linear_terms(model)
        Q[i, i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (Q, α, β)
end

QUBOTools.ising(model::AbstractQUBOModel{<:SpinDomain}) = QUBOTools.ising(Dict, model)

function QUBOTools.ising(::AbstractQUBOModel{<:BoolDomain})
    QUBOTools.codec_error(
        """
        Can't generate normal ising form from boolean model.
        Consider converting your model with `convert`"""
    )
end

function QUBOTools.ising(::Type{<:Dict}, model::AbstractQUBOModel{<:SpinDomain})
    h = QUBOTools.linear_terms(model; explicit=true)
    J = QUBOTools.quadratic_terms(model)
    α = QUBOTools.scale(model)
    β = QUBOTools.offset(model)

    return (h, J, α, β)
end

function QUBOTools.ising(::Type{<:Array}, model::AbstractQUBOModel{<:SpinDomain})
    n = length(s)
    h = zeros(Float64, n)
    J = zeros(Float64, n, n)
    α = QUBOTools.scale(model)
    β = QUBOTools.offset(model)

    for (i, hᵢ) in QUBOTools.linear_terms(model)
        h[i] = hᵢ
    end

    for ((i, j), Jᵢⱼ) in QUBOTools.quadratic_terms(model)
        J[i, j] = Jᵢⱼ
    end

    return (h, J, α, β)
end