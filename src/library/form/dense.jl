const LinearDenseForm{T}    = Vector{T}
const QuadraticDenseForm{T} = UpperTriangular{T,Matrix{T}}

@doc raw"""
    DenseForm{T}
"""
struct DenseForm{T} <: AbstractForm{T}
    n::Int
    L::LinearDenseForm{T}
    Q::QuadraticDenseForm{T}
    α::T
    β::T

    function DenseForm{T}(
        n::Integer,
        L::LinearDenseForm{T},
        Q::QuadraticDenseForm{T},
        α::T = one(T),
        β::T = zero(T),
    ) where {T}
        @assert size(L) == (n,)
        @assert size(Q) == (n, n)
        @assert α > zero(T)

        return new{T}(n, L, Q, α, β)
    end
end

function DenseForm{T}(Φ::F) where {T,S,F<:AbstractForm{S}}
    n = dimension(Φ)
    L = zeros(T, n)::LinearDenseForm{T}
    Q = zeros(T, n, n)::QuadraticDenseForm{T}
    α = convert(T, scale(Φ))
    β = convert(T, offset(Φ))

    for (i, v) in linear_terms(Φ)
        L[i] = convert(T, v)
    end

    for ((i, j), v) in quadratic_terms(Φ)
        Q[i, j] = convert(T, v)
    end

    return DenseForm{T}(n, L, Q, α, β)
end

dimension(Φ::DenseForm)       = Φ.n
linear_form(Φ::DenseForm)     = Φ.L
quadratic_form(Φ::DenseForm)  = Φ.Q
linear_terms(Φ::DenseForm)    = (i => Φ.L[i] for i = 1:Φ.n if !iszero(Φ.L[i]))
quadratic_terms(Φ::DenseForm) = ((i, j) => Φ.Q[i, j] for i = 1:Φ.n for j = (i+1):Φ.n if !iszero(Φ.Q[i, j]))
scale(Φ::DenseForm)           = Φ.α
offset(Φ::DenseForm)          = Φ.β
