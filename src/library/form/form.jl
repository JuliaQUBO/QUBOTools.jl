@doc raw"""
    Form{T,LF,LQ}
"""
struct Form{T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}} <: AbstractForm{T}
    n::Int
    L::LF
    Q::QF
    α::T
    β::T

    frame::Frame
end

function Form{T}(
    n::Integer,
    L::LF,
    Q::QF,
    α::T                         = one(T),
    β::T                         = zero(T);
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    frame = Frame(sense, domain)

    return Form{T,LF,QF}(n, L, Q, α, β, frame)
end

function Form{T,LF,QF}(
    n::Integer,
    L::LF,
    Q::QF,
    α::T                         = one(T),
    β::T                         = zero(T);
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    frame = Frame(sense, domain)

    return Form{T,LF,QF}(n, L, Q, α, β, frame)
end

function Form{T,LF,QF}(
    Φ::F,
) where {T,F<:AbstractForm{T},LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    n = dimension(Φ)

    return Form{T,LF,QF}(
        n,
        LF(n, linear_form(Φ)),
        QF(n, quadratic_form(Φ)),
        scale(Φ),
        offset(Φ);
        sense  = sense(Φ),
        domain = domain(Φ),
    )
end

function Base.copy(
    Φ::Form{T,LF,QF},
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    return Form{T,LF,QF}(
        dimension(Φ),
        copy(linear_form(Φ)),
        copy(quadratic_form(Φ)),
        scale(Φ),
        offset(Φ);
        sense  = sense(Φ),
        domain = domain(Φ),
    )
end

dimension(Φ::Form)      = Φ.n
linear_form(Φ::Form)    = Φ.L
quadratic_form(Φ::Form) = Φ.Q
scale(Φ::Form)          = Φ.α
offset(Φ::Form)         = Φ.β
frame(Φ::Form)          = Φ.frame

function cast(
    (s, t)::Route{S},
    Φ::Form{T,LF,QF},
) where {S<:Sense,T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    @assert s === sense(Φ)

    if s === t
        return Φ # no-op
    else
        n = dimension(Φ)
        L = linear_form(Φ)
        Q = quadratic_form(Φ)
        α = scale(Φ)
        β = -offset(Φ)

        l = LF(n, linear_size(L))
        q = QF(n, quadratic_size(Q))

        for (i, v) in linear_terms(L)
            l[i] = -v
        end

        for ((i, j), v) in quadratic_terms(Q)
            q[i, j] = -v
        end

        return Form{T,LF,QF}(n, l, q, α, β; sense = t, domain = domain(Φ))
    end
end

function cast(
    (s, t)::Route{D},
    Φ::Form{T,LF,QF},
) where {D<:Domain,T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    @assert s === domain(Φ)

    if s === t
        return Φ # no-op
    elseif s === 𝔹 && t === 𝕊
        n = dimension(Φ)
        L = linear_form(Φ)
        Q = quadratic_form(Φ)
        α = scale(Φ)
        β = offset(Φ)

        h = LF(n, linear_size(L))
        J = QF(n, quadratic_size(Q))

        for (i, v) in linear_terms(L)
            h[i] += v / 2
            β    += v / 2
        end

        for ((i, j), v) in quadratic_terms(Q)
            J[i, j] += v / 4
            h[i]    += v / 4
            h[j]    += v / 4
            β       += v / 4
        end

        return Form{T,LF,QF}(n, h, J, α, β; sense = sense(Φ), domain = t)
    elseif s === 𝕊 && t === 𝔹
        n = dimension(Φ)
        h = linear_form(Φ)
        J = quadratic_form(Φ)
        α = scale(Φ)
        β = offset(Φ)

        L = LF(n, linear_size(h))
        Q = QF(n, quadratic_size(J))

        for (i, v) in linear_terms(h)
            L[i] += 2v
            β    -= v
        end

        for ((i, j), v) in quadratic_terms(J)
            Q[i, j] += 4v
            L[i]    -= 2v
            L[j]    -= 2v
            β       += v
        end

        return Form{T,LF,QF}(n, L, Q, α, β; sense = sense(Φ), domain = t)
    else
        casting_error((s => t), Φ)
    end
end

function Form{T,LF,QF}(
    n::Integer,
    L::Any,
    Q::Any,
    α::T = one(T),
    β::T = zero(T);
    sense::Union{Sense,Symbol} = :min,
    domain::Union{Domain,Symbol} = :bool,
) where {T,LF,QF}
    return Form{T,LF,QF}(n, LF(L), QF(Q), α, β; sense, domain)
end
