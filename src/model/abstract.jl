model_name(::M) where {M<:AbstractModel} = "QUBO Model"

domain(::AbstractModel{D}) where {D} = D()
domain_name(::BoolDomain)                = "Bool"
domain_name(::SpinDomain)                = "Spin"
domain_name(model::AbstractModel)    = domain_name(domain(model))

Base.isempty(model::AbstractModel) = isempty(variable_map(model))

function explicit_linear_terms(model::AbstractModel)
    return _explicit_linear_terms(
        linear_terms(model),
        variable_inv(model)
    )
end

function _explicit_linear_terms(
    linear_terms::Dict{Int,T},
    variable_inv::Dict{Int},
) where {T}
    merge(
        Dict{Int,T}(i => zero(T) for i in keys(variable_inv)),
        linear_terms,
    )
end

function indices(model::AbstractModel)
    return collect(1:domain_size(model))
end

function variables(model::AbstractModel)
    return sort(collect(keys(variable_map(model))); lt=varcmp)
end

function variable_set(model::AbstractModel)
    return Set(keys(variable_map(model)))
end

function variable_map(model::AbstractModel, v)
    variable_map = QUBOTools.variable_map(model)

    if haskey(variable_map, v)
        return variable_map[v]
    else
        error("Variable '$v' does not belong to the model")
    end
end

function variable_inv(model::AbstractModel, i::Integer)
    variable_inv = QUBOTools.variable_inv(model)

    if haskey(variable_inv, i)
        return variable_inv[i]
    else
        error("Variable index '$i' does not belong to the model")
    end
end

# ~*~ Model's Normal Forms ~*~ #
qubo(model::AbstractModel{<:BoolDomain}) = qubo(model, Dict)

function qubo(model::AbstractModel{<:BoolDomain}, ::Type{Dict}, T::Type = Float64)
    n = domain_size(model)
    m = quadratic_size(model)

    Q = Dict{Tuple{Int,Int},T}()

    α::T = scale(model)
    β::T = offset(model)

    sizehint!(Q, m + n)

    for (i, qi) in explicit_linear_terms(model)
        Q[i, i] = qi
    end

    for ((i, j), Qij) in quadratic_terms(model)
        Q[i, j] = Qij
    end

    return (Q, α, β)
end

function qubo(model::AbstractModel{<:BoolDomain}, ::Type{Vector}, T::Type = Float64)
    n = domain_size(model)
    m = quadratic_size(model)

    L = zeros(T, n)
    Q = Vector{T}(undef, m)
    u = Vector{Int}(undef, m)
    v = Vector{Int}(undef, m)

    α::T = scale(model)
    β::T = offset(model)

    for (i, l) in linear_terms(model)
        L[i] = l
    end

    for (k, ((i, j), q)) in enumerate(quadratic_terms(model))
        Q[k] = q
        u[k] = i
        v[k] = j
    end

    return (L, Q, u, v, α, β)
end

function qubo(model::AbstractModel{<:BoolDomain}, ::Type{Matrix}, T::Type = Float64)
    n = domain_size(model)

    Q = zeros(T, n, n)

    α::T = scale(model)
    β::T = offset(model)

    for (i, l) in linear_terms(model)
        Q[i, i] = l
    end

    for ((i, j), q) in quadratic_terms(model)
        Q[i, j] = q
    end

    return (Q, α, β)
end

function qubo(model::AbstractModel{<:BoolDomain}, ::Type{SparseMatrixCSC}, T::Type = Float64)
    n = domain_size(model)

    Q = spzeros(T, n, n)

    α::T = scale(model)
    β::T = offset(model)

    for (i, l) in linear_terms(model)
        Q[i, i] = l
    end

    for ((i, j), q) in quadratic_terms(model)
        Q[i, j] = q
    end

    return (Q, α, β)
end

function qubo(model::AbstractModel{<:SpinDomain}, args...)
    return qubo(ising(model, args...)...)
end

ising(model::AbstractModel) = ising(model, Dict, Float64)

function ising(model::AbstractModel{<:SpinDomain}, ::Type{Dict}, T::Type = Float64)
    n = domain_size(model)
    m = quadratic_size(model)

    h = Dict{Int,T}()
    J = Dict{Tuple{Int,Int},T}()

    α::T = scale(model)
    β::T = offset(model)

    for (i, hi) in explicit_linear_terms(model)
        h[i] = hi
    end

    for ((i, j), Jij) in quadratic_terms(model)
        J[i, j] = Jij
    end

    return (h, J, α, β)
end

function ising(model::AbstractModel{<:SpinDomain}, ::Type{Vector}, T::Type = Float64)
    n = domain_size(model)
    m = quadratic_size(model)

    h = zeros(T, n)
    J = Vector{T}(undef, m)
    u = Vector{Int}(undef, m)
    v = Vector{Int}(undef, m)

    α::T = scale(model)
    β::T = offset(model)


    for (i, hi) in linear_terms(model)
        h[i] = hi
    end

    for (k, ((i, j), q)) in enumerate(quadratic_terms(model))
        J[k] = q
        u[k] = i
        v[k] = j
    end

    return (h, J, u, v, α, β)
end

function ising(model::AbstractModel{<:SpinDomain}, ::Type{Matrix}, T::Type = Float64)
    n = domain_size(model)

    h = zeros(T, n)
    J = zeros(T, n, n)

    α::T = scale(model)
    β::T = offset(model)

    for (i, hi) in linear_terms(model)
        h[i] = hi
    end

    for ((i, j), Jij) in quadratic_terms(model)
        J[i, j] = Jij
    end

    return (h, J, α, β)
end

function ising(model::AbstractModel{<:SpinDomain}, ::Type{SparseMatrixCSC}, T::Type = Float64)
    n = domain_size(model)

    h = spzeros(T, n)
    J = spzeros(T, n, n)

    α::T = scale(model)
    β::T = offset(model)

    for (i, hi) in linear_terms(model)
        h[i] = hi
    end

    for ((i, j), Jij) in quadratic_terms(model)
        J[i, j] = Jij
    end

    return (h, J, α, β)
end

function ising(model::AbstractModel{<:BoolDomain}, args...)
    return ising(qubo(model, args...)...)
end

# ~*~ Data queries ~*~ #
function QUBOTools.state(model::AbstractModel, index::Integer)
    return QUBOTools.state(QUBOTools.sampleset(model), index)
end

function QUBOTools.reads(model::AbstractModel)
    return QUBOTools.reads(QUBOTools.sampleset(model))
end

function QUBOTools.reads(model::AbstractModel, index::Integer)
    return QUBOTools.reads(QUBOTools.sampleset(model), index)
end

function QUBOTools.value(model::AbstractModel, index::Integer)
    return QUBOTools.value(QUBOTools.sampleset(model), index)
end

function QUBOTools.value(model::AbstractModel, ψ::Vector{U}) where {U<:Integer}
    α = QUBOTools.scale(model)
    e = QUBOTools.offset(model)

    for (i, l) in QUBOTools.linear_terms(model)
        e += ψ[i] * l
    end

    for ((i, j), q) in QUBOTools.quadratic_terms(model)
        e += ψ[i] * ψ[j] * q
    end

    return α * e
end

# ~*~ Queries: sizes & density ~*~ #
QUBOTools.domain_size(model::AbstractModel)    = length(QUBOTools.variable_map(model))
QUBOTools.linear_size(model::AbstractModel)    = length(QUBOTools.linear_terms(model))
QUBOTools.quadratic_size(model::AbstractModel) = length(QUBOTools.quadratic_terms(model))

function QUBOTools.density(model::AbstractModel)
    n = QUBOTools.domain_size(model)

    if n == 0
        return NaN
    else
        l = QUBOTools.linear_size(model)
        q = QUBOTools.quadratic_size(model)

        return (2 * q + l) / (n * n)
    end
end

function QUBOTools.linear_density(model::AbstractModel)
    n = QUBOTools.domain_size(model)

    if n == 0
        return NaN
    else
        l = QUBOTools.linear_size(model)

        return l / n
    end
end

function QUBOTools.quadratic_density(model::AbstractModel)
    n = QUBOTools.domain_size(model)

    if n <= 1
        return NaN
    else
        q = QUBOTools.quadratic_size(model)

        return (2 * q) / (n * (n - 1))
    end
end

function QUBOTools.adjacency(model::AbstractModel)
    n = QUBOTools.domain_size(model)
    A = Dict{Int,Set{Int}}(i => Set{Int}() for i = 1:n)

    for (i, j) in keys(QUBOTools.quadratic_terms(model))
        push!(A[i], j)
        push!(A[j], i)
    end

    return A
end

function QUBOTools.adjacency(model::AbstractModel, k::Integer)
    A = Set{Int}()

    for (i, j) in keys(QUBOTools.quadratic_terms(model))
        if i == k
            push!(A, j)
        elseif j == k
            push!(A, i)
        end
    end

    return A
end

# ~*~ Internal: bridge validation ~*~ #


# ~*~ I/O ~*~ #
function Base.read(::IO, M::Type{<:AbstractModel})
    QUBOTools.codec_error("'Base.read' not implemented for model of type '$(M)'")
end

function Base.read(path::AbstractString, M::Type{<:AbstractModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(::IO, model::AbstractModel)
    QUBOTools.codec_error("'Base.write' not implemented for model of type '$(typeof(model))'")
end

function Base.write(path::AbstractString, model::AbstractModel)
    open(path, "w") do io
        return write(io, model)
    end
end

bridge(::Type{M}, model::M) where {M<:AbstractModel} = model

function Base.convert(::Type{A}, model::B) where {A<:AbstractModel,B<:AbstractModel}
    if hasbridge(A, B)
        return bridge(A, model)
    else
        return chain(A, model)
    end
end

function Base.copy!(::M, ::M) where {M<:AbstractModel}
    QUBOTools.codec_error("'Base.copy!' not implemented for copying '$M' models in-place")
end

function Base.copy!(
    target::X,
    source::Y,
) where {X<:AbstractModel,Y<:AbstractModel}
    copy!(target, convert(X, source))
end

function Base.show(io::IO, model::AbstractModel)
    if !isempty(model)
        print(
            io,
            """
            $(model_name(model)):
            $(domain_size(model)) variables [$(domain_name(model))]

            Density:
            linear    ~ $(@sprintf("%0.2f", 100.0 * linear_density(model)))%
            quadratic ~ $(@sprintf("%0.2f", 100.0 * quadratic_density(model)))%
            total     ~ $(@sprintf("%0.2f", 100.0 * density(model)))%
            """
        )
    else
        print(
            io,
            """
            $(model_name(model)) Model:
            $(domain_size(model)) variables [$(domain_name(model))]

            The model is empty
            """
        )
    end
end