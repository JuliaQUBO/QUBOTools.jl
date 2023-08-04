const LinearSparseForm{T}    = SparseVector{T}
const QuadraticSparseForm{T} = SparseMatrixCSC{T}

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
        l = spzeros(T, n)
        q = spzeros(T, n, n)

        for (i, v) in zip(findnz(L)...)
            iszero(v) && continue

            l[i] += v
        end

        for (i, j, v) in zip(findnz(Q)...)
            iszero(v) && continue

            if i == j
                l[i] += v
            elseif i > j
                q[j, i] += v
            else # i < j
                q[i, j] += v
            end
        end

        dropzeros!(l)
        dropzeros!(q)

        return new{T}(n, l, q, α, β)
    end
end

function SparseForm{T}(Φ::F) where {T,S,F<:AbstractForm{S}}
    n = dimension(Φ)
    L = spzeros(T, n)::LinearSparseForm{T}
    Q = spzeros(T, n, n)::QuadraticSparseForm{T}
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
linear_size(Φ::SparseForm)     = nnz(Φ.L)
quadratic_size(Φ::SparseForm)  = nnz(Φ.Q)
scale(Φ::SparseForm)           = Φ.α
offset(Φ::SparseForm)          = Φ.β

function cast((s, t)::Route{D}, Φ::F) where {D<:Domain,T,F<:SparseForm{T}}
    if s === t
        return Φ
    elseif s === 𝔹 && t === 𝕊
        n, L, Q, α, β = Φ

        h = spzeros(T, n)
        J = spzeros(T, n, n)

        for (i, v) in zip(findnz(L)...)
            h[i] += v / 2
            β    += v / 2
        end

        for (i, j, v) in zip(findnz(Q)...)
            J[i, j] += v / 4
            h[i]    += v / 4
            h[j]    += v / 4
            β       += v / 4
        end

        return F(n, h, J, α, β)
    elseif s === 𝕊 && t === 𝔹
        n, h, J, α, β = Φ

        L = spzeros(T, n)
        Q = spzeros(T, n, n)

        for (i, v) in zip(findnz(h)...)
            L[i] += 2v
            β    -= v
        end

        for (i, j, v) in zip(findnz(J)...)
            Q[i, j] += 4v
            L[i]    -= 2v
            L[j]    -= 2v
            β       += v
        end

        return F(n, L, Q, α, β)
    else
        casting_error(s => t, Φ)
    end
end

# Choose sparse as normal Φ
const LinearNormalForm{T}    = LinearSparseForm{T}
const QuadraticNormalForm{T} = QuadraticSparseForm{T}
const NormalForm{T}          = SparseForm{T}
