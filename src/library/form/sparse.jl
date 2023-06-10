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

function SparseForm{T}(Φ::F) where {T,S,F<:AbstractForm{S}}
    n = dimension(Φ)
    L = spzeros(T, n)::LinearSparseForm{T}
    Q = QuadraticSparseForm{T}(spzeros(T, n, n))
    α = convert(T, scale(Φ))
    β = convert(T, offset(Φ))

    for (i, v) in linear_terms(Φ)
        L[i] = convert(T, v)
    end

    for ((i, j), v) in quadratic_terms(Φ)
        Q[i, j] = convert(T, v)
    end

    return SparseForm{T}(n, L, Q, α, β)
end

dimension(Φ::SparseForm)       = Φ.n
linear_form(Φ::SparseForm)     = Φ.L
quadratic_form(Φ::SparseForm)  = Φ.Q
linear_terms(Φ::SparseForm)    = (i => v for (i, v) in zip(findnz(Φ.L)...))
quadratic_terms(Φ::SparseForm) = ((i, j) => v for (i, j, v) in zip(findnz(Φ.Q)...))
scale(Φ::SparseForm)           = Φ.α
offset(Φ::SparseForm)          = Φ.β

function cast((s, t)::Route{D}, Φ::F) where {D<:Domain,T,F<:SparseForm{T}}
    if s === t
        return Φ
    elseif s === 𝔹 && t === 𝕊
        n, L, Q, α, β = Φ

        h = L / 2 + sum(Q + Q'; dims=2) / 4 |> LinearSparseForm{T}
        J = Q / 4                           |> QuadraticSparseForm{T}
        β = β + sum(L) / 2 + sum(Q) / 4

        return F(n, h, J, α, β)
    elseif s === 𝕊 && t === 𝔹
        n, h, J, α, β = Φ

        L = 2 * h - 2 * sum(J + J'; dims=2) |> LinearSparseForm{T}
        Q = 4 * J                           |> QuadraticSparseForm{T}
        β = β + sum(L) - sum(Q)

        return F(n, L, Q, α, β)
    else
        casting_error(s => t, Φ)
    end
end

# Choose sparse as normal Φ
const LinearNormalForm{T}    = LinearSparseForm{T}
const QuadraticNormalForm{T} = QuadraticSparseForm{T}
const NormalForm{T}          = SparseForm{T}
