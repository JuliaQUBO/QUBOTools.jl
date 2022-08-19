QUBOTools.backend(model::StandardQUBOModel) = model

QUBOTools.domain_name(model::AbstractQUBOModel{<:BoolDomain}) = "Bool"
QUBOTools.domain_name(model::AbstractQUBOModel{<:SpinDomain}) = "Spin"

QUBOTools.linear_terms(model::StandardQUBOModel) = model.linear_terms
QUBOTools.quadratic_terms(model::StandardQUBOModel) = model.quadratic_terms
QUBOTools.variable_map(model::StandardQUBOModel) = model.variable_map
QUBOTools.variable_map(model::StandardQUBOModel{V,<:Any,<:Any,<:Any}, v::V) where {V} = model.variable_map[v]
QUBOTools.variable_inv(model::StandardQUBOModel) = model.variable_inv
QUBOTools.variable_inv(model::StandardQUBOModel, i::Integer) = model.variable_inv[i]

function QUBOTools.energy(state::Vector{U}, model::StandardQUBOModel{<:Any,U,T,<:Any}) where {U,T}
    s = zero(T)

    for (i, l) in model.linear_terms
        s += state[i] * l
    end

    for ((i, j), q) in model.quadratic_terms
        s += state[i] * state[j] * q
    end

    return s
end

function linear_terms(model; explicit::Bool=false)
    linear_terms = QUBOTools.linear_terms(QUBOTools.backend(model))

    if explicit
        return QUBOTools._explicit_linear_terms(
            linear_terms,
            QUBOTools.variable_inv(model)
        )
    else
        return linear_terms
    end
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

domain_size(model) = length(QUBOTools.variable_map(model))
linear_size(model) = length(QUBOTools.linear_terms(model))
quadratic_size(model) = length(QUBOTools.quadratic_terms(model))

function density(model::Any)
    n = QUBOTools.domain_size(model)
    if n == 0
        return 0.0
    else
        l = QUBOTools.linear_size(model)
        q = QUBOTools.quadratic_size(model)
        return (2 * q + l) / (n * n)
    end
end

function linear_density(model::Any)
    n = QUBOTools.domain_size(model)

    if n == 0
        return 0.0
    else
        l = QUBOTools.linear_size(model)
        return l / n
    end
end

function quadratic_density(model::Any)
    n = QUBOTools.domain_size(model)

    if n <= 1
        return 0.0
    else
        q = QUBOTools.quadratic_size(model)
        return (2 * q) / (n * (n - 1))
    end
end