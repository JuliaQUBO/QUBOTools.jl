const LinearVectorForm{T}    = Vector{T}
const QuadraticVectorForm{T} = Tuple{Vector{Int},Vector{Int},Vector{T}}

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
        @assert α > zero(T)

        

        return new{T}(n, L, Q, α, β)
    end
end

function VectorForm{T}(Φ::F) where {T,S,F<:AbstractForm{S}}
    n = dimension(Φ)
    L = zeros(T, n)::LinearVectorForm{T}
    Q = QuadraticVectorForm{T}(Int[], Int[], T[])
    α = convert(T, scale(Φ))
    β = convert(T, offset(Φ))

    I, J, V = Q

    for (i, v) in linear_terms(Φ)
        L[i] = convert(T, v)
    end

    for ((i, j), v) in quadratic_terms(Φ)
        push!(I, i)
        push!(J, j)
        push!(V, convert(T, v))
    end

    return VectorForm{T}(n, L, Q, α, β)
end

dimension(Φ::VectorForm)       = Φ.n
linear_form(Φ::VectorForm)     = Φ.L
quadratic_form(Φ::VectorForm)  = Φ.Q
linear_terms(Φ::VectorForm)    = (i => v for (i, v) in enumerate(Φ.L) if !iszero(v))
quadratic_terms(Φ::VectorForm) = ((i, j) => v for (i, j, v) in zip(Φ.Q...))
scale(Φ::VectorForm)           = Φ.α
offset(Φ::VectorForm)          = Φ.β

function cast((s, t)::Route{S}, Q::QuadraticVectorForm{T}) where {S<:Sense,T}
    if s === t
        return Q
    else
        I, J, V = Q

        return QuadraticVectorForm{T}(I, J, -V)
    end
end

function value(Φ::VectorForm{T}, ψ::State{U}) where {T,U}
    _, L, (V, I, J), α, β = Φ

    return value(L, I, J, V, ψ, α, β)
end

function value(
    L::AbstractVector{T},
    I::AbstractVector{Int},
    J::AbstractVector{Int},
    V::AbstractVector{T},
    ψ::State{U},
    α::T = one(T),
    β::T = zero(T),
) where {T,U}
    λ = zero(T)

    for i in eachindex(L)
        λ += ψ[i] * L[i]
    end

    for (i, j, v) in zip(I, J, V)
        λ += ψ[i] * ψ[j] * v
    end

    return α * (λ + β)
end
