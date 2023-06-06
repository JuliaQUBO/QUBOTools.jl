# Sense
function cast((s, t)::Route{S}, L::LinearDictForm{T}) where {S<:Sense,T}
    return LinearDictForm{T}(i => -v for (i, v) in L)
end

function cast((s, t)::Route{S}, Q::QuadraticDictForm{T}) where {S<:Sense,T}
    return QuadraticDictForm{T}(ij => -v for (ij, v) in Q)
end

function cast((s, t)::Route{S}, L::LinearMatrixForm{T}) where {S<:Sense,T}
    return -L
end

function cast((s, t)::Route{S}, Q::QuadraticMatrixForm{T}) where {S<:Sense,T}
    return -Q
end

function cast((s, t)::Route{S}, L::LinearSparseForm{T}) where {S<:Sense,T}
    return -L
end

function cast((s, t)::Route{S}, Q::QuadraticSparseForm{T}) where {S<:Sense,T}
    return -Q
end

function cast((s, t)::Route{S}, L::LinearVectorForm{T}) where {S<:Sense,T}
    return -L
end

function cast((s, t)::Route{S}, Q::QuadraticVectorForm{T}) where {S<:Sense,T}
    V, I, J = Q

    return QuadraticVectorForm{T}(-V, I, J)
end

function cast((s, t)::Route{S}, form::F) where {S<:Sense,T,F<:AbstractForm{T}}
    if s === t
        return form
    else
        n = dimension(form)
        L = cast(s => t, linear_form(form))
        Q = cast(s => t, quadratic_form(form))
        α = scale(form)
        β = -offset(form)

        return F(n, L, Q, α, β)
    end
end

# Domain
function cast((s, t)::Route{D}, form::SparseForm{T}) where {D<:Domain,T}
    if s === t
        return form
    elseif s === 𝔹 && t === 𝕊
        n = dimension(form)
        L = linear_form(form)
        Q = quadratic_form(form)
        α = scale(form)
        β = offset(form)

        h = L / 2 + sum(Q + Q'; dims=2) / 4 |> LinearNormalForm{T}
        J = Q / 4                           |> QuadraticNormalForm{T}
        β = β + sum(L) / 2 + sum(Q) / 4

        return SparseForm{T}(n, h, J, α, β)
    elseif s === 𝕊 && t === 𝔹
        n = dimension(form)
        h = linear_form(form)
        J = quadratic_form(form)
        α = scale(form)
        β = offset(form)

        L = 2 * h - 2 * sum(J + J'; dims=2) |> LinearNormalForm{T}
        Q = 4 * J                           |> QuadraticNormalForm{T}
        β = β + sum(L) - sum(Q)

        return SparseForm{T}(n, L, Q, α, β)
    else
        casting_error(s => t, form)
    end
end

function cast((s, t)::Route{D}, form::F) where {D<:Domain,T,F<:AbstractForm{T}}
    if s === t
        return form
    else
        return F(cast(s => t, NormalForm{T}(form)))
    end
end