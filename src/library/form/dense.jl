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

    frame::Frame

    function DenseForm{T}(
        n::Integer,
        L::AbstractVector{T},
        Q::AbstractMatrix{T},
        α::T = one(T),
        β::T = zero(T);
        sense::Union{Sense,Symbol}   = :min,
        domain::Union{Domain,Symbol} = :bool,
    ) where {T}
        frame = Frame(sense, domain)

        l = zeros(T, n)::LinearDenseForm{T}
        q = UpperTriangular{T,Matrix{T}}(zeros(T, n, n))::QuadraticDenseForm{T}

        for i = 1:n
            l[i] = L[i] + Q[i, i]
        end

        for i = 1:n, j = (i+1):n
            q[i, j] = Q[i, j] + Q[j, i]
        end

        return new{T}(n, l, q, α, β, frame)
    end
end

function DenseForm{T}(Φ::F) where {T,S,F<:AbstractForm{S}}
    n = dimension(Φ)
    L = zeros(T, n)::LinearDenseForm{T}
    Q = UpperTriangular{T,Matrix{T}}(zeros(T, n, n))
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
frame(Φ::DenseForm)           = Φ.frame
sense(Φ::DenseForm)           = sense(frame(Φ))
domain(Φ::DenseForm)          = domain(frame(Φ))

function linear_size(Φ::F) where {T,F<:DenseForm{T}}
    return count(!iszero, Φ.L)
end

function quadratic_size(Φ::F) where {T,F<:DenseForm{T}}
    return count(!iszero, Φ.Q)
end
