# Adding an iterate interface allows struct unpacking, i.e.,
# n, L, Q, α, β = form
function Base.iterate(Φ::F, state::Integer = 1) where {T,F<:AbstractForm{T}}
    if state == 1
        return (dimension(Φ), state + 1)
    elseif state == 2
        return (linear_form(Φ), state + 1)
    elseif state == 3
        return (quadratic_form(Φ), state + 1)
    elseif state == 4
        return (scale(Φ), state + 1)
    elseif state == 5
        return (offset(Φ), state + 1)
    else
        return nothing
    end
end

function adjacency(Φ::F; tol::T = zero(T)) where {T,F<:AbstractForm{T}}
    n = dimension(Φ)
    A = spzeros(Int, n, n)

    for ((i, j), v) in quadratic_terms(Φ)
        if abs(v) > tol
            A[i,j] = 1
        end
    end

    return Symmetric(A)
end

function adjacency(Φ::F, k::Integer; tol::T = zero(T)) where {T,F<:AbstractForm{T}}
    n = dimension(Φ)
    A = spzeros(Int, n)

    for ((i, j), v) in quadratic_terms(Φ)
        if abs(v) <= tol
            continue
        elseif i == k
            A[j] = 1
        elseif j == k
            A[i] = 1
        end
    end

    return A
end

# Abstract methods
function cast((s, t)::Route{S}, A::AbstractArray{T,N}) where {S<:Sense,T,N}
    if s === t
        return A
    else
        return -A
    end
end

function cast((s, t)::Route{S}, Φ::F) where {S<:Sense,T,F<:AbstractForm{T}}
    if s === t
        return Φ
    else
        n = dimension(Φ)
        L = cast(s => t, linear_form(Φ))
        Q = cast(s => t, quadratic_form(Φ))
        α = scale(Φ)
        β = -offset(Φ)

        return F(n, L, Q, α, β)
    end
end

function cast((s, t)::Route{D}, Φ::F) where {D<:Domain,T,F<:AbstractForm{T}}
    if s === t
        return Φ
    elseif s === 𝔹 && t === 𝕊 || s === 𝕊 && t === 𝔹
        return F(cast(s => t, NormalForm{T}(Φ)))
    else
        casting_error(s => t, Φ)
    end
end