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

function DictForm{T}(Φ::F) where {T,S,F<:AbstractForm{S}}
    n = dimension(Φ)
    L = LinearDictForm{T}(linear_terms(Φ))
    Q = QuadraticDictForm{T}(quadratic_terms(Φ))
    α = convert(T, scale(Φ))
    β = convert(T, offset(Φ))

    return DictForm{T}(n, L, Q, α, β)
end

dimension(Φ::DictForm)       = Φ.n
linear_form(Φ::DictForm)     = Φ.L
quadratic_form(Φ::DictForm)  = Φ.Q
linear_terms(Φ::DictForm)    = (i => v for (i, v) in Φ.L if !iszero(v))
quadratic_terms(Φ::DictForm) = (ij => v for (ij, v) in Φ.Q if !iszero(v))
scale(Φ::DictForm)           = Φ.α
offset(Φ::DictForm)          = Φ.β

function cast((s, t)::Route{S}, L::LinearDictForm{T}) where {S<:Sense,T}
    if s === t
        return L
    else
        return LinearDictForm{T}(i => -v for (i, v) in L)
    end
end

function cast((s, t)::Route{S}, Q::QuadraticDictForm{T}) where {S<:Sense,T}
    if s === t
        return Q
    else
        return QuadraticDictForm{T}(ij => -v for (ij, v) in Q)
    end
end

function value(Φ::DictForm, ψ::State{U}) where {U}
    _, L, Q, α, β = Φ

    return value(L, Q, ψ, α, β)
end

function value(
    L::AbstractDict{Int,T},
    Q::AbstractDict{Tuple{Int,Int},T},
    ψ::State{U},
    α::T = one(T),
    β::T = zero(T),
) where {T,U}
    e = zero(T)

    for (i, c) in L
        e += ψ[i] * c
    end

    for ((i, j), c) in Q
        e += ψ[i] * ψ[j] * c
    end

    return α * (e + β)
end