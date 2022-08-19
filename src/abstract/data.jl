Base.isvalid(::AbstractQUBOModel) = false
Base.isempty(model::AbstractQUBOModel) = (QUBOTools.domain_size(model) == 0)

QUBOTools.__isvalidbridge(
    source::M,
    target::M,
    ::Type{<:AbstractQUBOModel};
    kws...
) where {M<:AbstractQUBOModel} = false

QUBOTools.domain_name(model::AbstractQUBOModel{<:BoolDomain}) = "Bool"
QUBOTools.domain_name(model::AbstractQUBOModel{<:SpinDomain}) = "Spin"

QUBOTools.domain_size(model::AbstractQUBOModel) = length(QUBOTools.variable_map(model))
QUBOTools.linear_size(model::AbstractQUBOModel) = length(QUBOTools.linear_terms(model))
QUBOTools.quadratic_size(model::AbstractQUBOModel) = length(QUBOTools.quadratic_terms(model))

QUBOTools.qubo(model::AbstractQUBOModel{<:BoolDomain}) = QUBOTools.qubo(Dict, Float64, model)

function QUBOTools.qubo(::Type{<:Dict}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    x = QUBOTools.variable_map(model)
    Q = Dict{Tuple{Int,Int},T}()
    α::T = QUBOTools.scale(model)
    β::T = QUBOTools.offset(model)

    for (i, qᵢ) in QUBOTools.linear_terms(model)
        Q[i, i] = qᵢ
    end

    for ((i, j), qᵢⱼ) in QUBOTools.quadratic_terms(model)
        Q[i, j] = qᵢⱼ
    end

    return (x, Q, α, β)
end

function QUBOTools.qubo(::Type{<:Array}, T::Type, model::AbstractQUBOModel{<:BoolDomain})
    x = QUBOTools.variable_map(model)
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

    return (x, Q, α, β)
end

QUBOTools.ising(model::AbstractQUBOModel{<:SpinDomain}) = QUBOTools.ising(Dict, model)

function QUBOTools.ising(::Type{<:Dict}, model::AbstractQUBOModel{<:SpinDomain})
    s = QUBOTools.variable_map(model)
    h = QUBOTools.linear_terms(model)
    J = QUBOTools.quadratic_terms(model)
    α = QUBOTools.scale(model)
    β = QUBOTools.offset(model)

    return (s, h, J, α, β)
end

function QUBOTools.ising(::Type{<:Array}, model::AbstractQUBOModel{<:SpinDomain})
    s = QUBOTools.variable_map(model)
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

    return (s, h, J, α, β)
end