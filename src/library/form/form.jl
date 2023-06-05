const LinearDictForm{T}    = Dict{Int,T}
const QuadraticDictForm{T} = Dict{Tuple{Int,Int},T}

@doc raw"""
    DictForm{T}
"""
struct DictForm{T} <: AbstractForm{T}
    n::Int
    L::LinearDictForm{T}
    Q::QuadraticDictForm{T}
    α::T
    β::T

    function DictForm{T}(
        n::Integer,
        L::LinearDictForm{T},
        Q::QuadraticDictForm{T},
        α::T = one(T),
        β::T = zero(T),
    ) where {T}
        @assert α > zero(T)

        return new{T}(n, L, Q, α, β)
    end
end

function DictForm{T}(form::F) where {F<:AbstractForm}
    n = dimension(form)
    L = LinearDictForm{T}(i => v for (i, v) in linear_terms(form) if !iszero(v))
    Q = QuadraticDictForm{T}(ij => v for (ij, v) in quadratic_terms(form) if !iszero(v))
    α = convert(T, scale(form))
    β = convert(T, offset(form))

    return DictForm{T}(n, L, Q, α, β)
end

dimension(form::DictForm)     = form.n
linear_terms(form::DictForm)    = form.L
quadratic_terms(form::DictForm) = form.Q
scale(form::DictForm)           = form.α
offset(form::DictForm)          = form.β

const LinearMatrixForm{T}    = Vector{T}
const QuadraticMatrixForm{T} = Matrix{T}

@doc raw"""
    MatrixForm{T}
"""
struct MatrixForm{T} <: AbstractForm{T}
    n::Int
    L::LinearMatrixForm{T}
    Q::QuadraticMatrixForm{T}
    α::T
    β::T

    function MatrixForm{T}(
        n::Integer,
        L::LinearMatrixForm{T},
        Q::QuadraticMatrixForm{T},
        α::T = one(T),
        β::T = zero(T),
    ) where {T}
        @assert size(L) == (n,)
        @assert size(Q) == (n, n)
        @assert α > zero(T)

        return new{T}(n, L, Q, α, β)
    end
end

function MatrixForm{T}(form::F) where {F<:AbstractForm}
    n = dimension(form)
    L = zeros(T, n)::LinearMatrixForm{T}
    Q = zeros(T, n, n)::QuadraticMatrixForm{T}
    α = convert(T, scale(form))
    β = convert(T, offset(form))

    for (i, v) in linear_terms(form)
        L[i] = convert(T, v)
    end

    for ((i, j)v) in quadratic_terms(form)
        Q[i, j] = convert(T, v)
    end

    return MatrixForm{T}(n, L, Q, α, β)
end

dimension(form::MatrixForm)     = form.n
linear_terms(form::MatrixForm)    = (i => form.L for i = 1:form.n)
quadratic_terms(form::MatrixForm) = ((i, j) => form.Q[i, j] for i = 1:form.n for j = (i+1):form.n)
scale(form::MatrixForm)           = form.α
offset(form::MatrixForm)          = form.β

const LinearSparseForm{T}    = SparseVector{T}
const QuadraticSparseForm{T} = UpperTriangular{T,SparseMatrixCSC{T}}

@doc raw"""
    SparseForm{T}
"""
struct SparseForm{T} <: AbstractForm{T}
    n::Int
    L::LinearSparseForm{T}
    Q::QuadraticSparseForm{T}
    α::T
    β::T

    function SparseForm{T}(
        n::Integer,
        L::LinearSparseForm{T},
        Q::QuadraticSparseForm{T},
        α::T = one(T),
        β::T = zero(T),
    ) where {T}
        @assert size(L) == (n,)
        @assert size(Q) == (n, n)
        @assert α > zero(T)

        return new{T}(n, L, Q, α, β)
    end
end

function SparseForm{T}(form::F) where {F<:AbstractForm}
    n = dimension(form)
    L = spzeros(T, n)::LinearSparseForm{T}
    Q = QuadraticSparseForm{T}(spzeros(T, n, n))
    α = convert(T, scale(form))
    β = convert(T, offset(form))

    for (i, v) in linear_terms(form)
        L[i] = convert(T, v)
    end

    for ((i, j)v) in quadratic_terms(form)
        Q[i, j] = convert(T, v)
    end

    return SparseForm{T}(n, L, Q, α, β)
end

dimension(form::SparseForm)     = form.n
linear_terms(form::SparseForm)    = (i => v for (i, v) in zip(findnz(form.L)...))
quadratic_terms(form::SparseForm) = ((i, j) => v for (i, j, v) in zip(findnz(form.Q)...))
scale(form::SparseForm)           = form.α
offset(form::SparseForm)          = form.β

const LinearVectorForm{T}    = Vector{T}
const QuadraticVectorForm{T} = Tuple{Vector{T},Vector{Int},Vector{Int}}

@doc raw"""
    VectorForm{T}
"""
struct VectorForm{T} <: AbstractForm{T}
    n::Int
    L::LinearVectorForm{T}
    Q::QuadraticVectorForm{T}
    α::T
    β::T

    function VectorForm{T}(
        n::Integer,
        L::LinearVectorForm{T},
        Q::QuadraticVectorForm{T},
        α::T = one(T),
        β::T = zero(T),
    ) where {T}
        @assert length(L) == n
        @assert allequal(length.(Q))
        @assert α > zero(T)

        return new{T}(n, L, Q, α, β)
    end
end

function VectorForm{T}(form::F) where {F<:AbstractForm}
    n = dimension(form)
    L = zeros(T, n)::LinearVectorForm{T}
    Q = QuadraticVectorForm{T}(Vector{T}(), Vector{Int}(), Vector{Int}())
    α = convert(T, scale(form))
    β = convert(T, offset(form))

    V, I, J = Q

    for (i, v) in linear_terms(form)
        L[i] = convert(T, v)
    end

    for ((i, j), v) in quadratic_terms(form)
        push!(I, i)
        push!(J, j)
        push!(V, convert(T, v))
    end

    return VectorForm{T}(n, L, Q, α, β)
end

dimension(form::VectorForm)     = form.n
linear_terms(form::VectorForm)    = (i => v for (i, v) in enumerate(form.L))
quadratic_terms(form::VectorForm) = ((i, j) => v for (v, i, j) in zip(form.Q...))
scale(form::VectorForm)           = form.α
offset(form::VectorForm)          = form.β

# Choose the sparse form as default
const LinearNormalForm{T}    = LinearSparseForm{T}
const QuadraticNormalForm{T} = QuadraticSparseForm{T}
const NormalForm{T}          = SparseForm{T}
