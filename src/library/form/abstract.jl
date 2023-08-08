# Adding an iterate interface allows struct unpacking, i.e.,
# n, L, Q, α, β, sense, domain = form
Base.length(::F) where {T,F<:AbstractForm{T}} = 7

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
    elseif state == 6
        return (sense(Φ), state + 1)
    elseif state == 7
        return (domain(Φ), state + 1)
    else
        return nothing
    end
end

# Comparison
function Base.:(==)(Φ::F, Ψ::F) where {T,F<:AbstractForm{T}}
    return dimension(Φ) == dimension(Ψ) &&
           scale(Φ) == scale(Ψ) &&
           offset(Φ) == offset(Ψ) &&
           linear_form(Φ) == linear_form(Ψ) &&
           quadratic_form(Φ) == quadratic_form(Ψ)
end

function Base.isapprox(Φ::F, Ψ::F; kws...) where {T,F<:AbstractForm{T}}
    return dimension(Φ) == dimension(Ψ) &&
           isapprox(scale(Φ), scale(Ψ); kws...) &&
           isapprox(offset(Φ), offset(Ψ); kws...) &&
           _isapprox(linear_form(Φ), linear_form(Ψ); kws...) &&
           _isapprox(quadratic_form(Φ), quadratic_form(Ψ); kws...)
end

function _isapprox(x, y; kws...)
    return isapprox(x, y; kws...)
end

function _isapprox(x::Dict{V,T}, y::Dict{V,T}; kws...) where {V,T}
    for k in union(keys(x), keys(y))
        if !isapprox(get(x, k, zero(T)), get(y, k, zero(T)); kws...)
            return false
        end
    end

    return true
end

function topology(Φ::F; kws...) where {T,F<:AbstractForm{T}}
    n = dimension(Φ)
    A = spzeros(Int, n, n)

    for ((i, j), v) in quadratic_terms(Φ)
        if isapprox(v, zero(T); kws...)
            A[i, j] = 1
        end
    end

    return Symmetric(A)
end

function topology(Φ::F, k::Integer; kws...) where {T,F<:AbstractForm{T}}
    n = dimension(Φ)
    A = spzeros(Int, n)

    for ((i, j), v) in quadratic_terms(Φ)
        if isapprox(v, zero(T); kws...)
            if i == k
                A[j] = 1
            elseif j == k
                A[i] = 1
            end
        end
    end

    return A
end

function cast(t::Domain, Φ::F) where {T,F<:AbstractForm{T}}
    return cast(domain(Φ) => t, Φ)
end

function cast((s, t)::Route{S}, A::AbstractArray{T,N}) where {S<:Sense,T,N}
    if s === t
        return A
    else
        return -A
    end
end

function cast((s, t)::Route{S}, Φ::F) where {S<:Sense,T,F<:AbstractForm{T}}
    @assert sense(Φ) === s

    if s === t
        return Φ
    else
        n = dimension(Φ)
        L = cast(s => t, linear_form(Φ))
        Q = cast(s => t, quadratic_form(Φ))
        α = scale(Φ)
        β = -offset(Φ)

        return F(n, L, Q, α, β; sense = t, domain = domain(Φ))
    end
end

function cast((s, t)::Route{D}, Φ::F) where {D<:Domain,T,F<:AbstractForm{T}}
    @assert domain(Φ) === s

    if s === t
        return Φ
    elseif s === 𝔹 && t === 𝕊 || s === 𝕊 && t === 𝔹
        return F(cast(s => t, NormalForm{T}(Φ)))
    else
        casting_error(s => t, Φ)

        return nothing
    end
end

function linear_size(Φ::F) where {T,F<:AbstractForm{T}}
    return length(linear_terms(Φ))
end

function quadratic_size(Φ::F) where {T,F<:AbstractForm{T}}
    return length(quadratic_terms(Φ))
end
