# Abstract
const Route{X} = Pair{X,X}

# Sense
cast(::Route{S}, ℓ::Dict{Int,T}) where {T,S<:Sense} = ℓ

function cast(::Pair{A,B}, L̄::Dict{Int,T}) where {T,A<:Sense,B<:Sense}
    L = sizehint!(Dict{Int,T}(), length(L̄))

    for (i, c) in L̄
        L[i] = -c
    end

    return L
end

function cast(::Pair{S,S}, Q̄::Dict{Tuple{Int,Int},T}) where {T,S<:Sense}
    return copy(Q̄)
end

function cast(::Pair{A,B}, Q̄::Dict{Tuple{Int,Int},T}) where {T,A<:Sense,B<:Sense}
    Q = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q̄))

    for (ij, c) in Q̄
        Q[ij] = -c
    end

    return Q
end

function cast(
    ::Pair{S,S},
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T,S<:Sense}
    L = copy(L̄)
    Q = copy(Q̄)

    return (L, Q, α, β)
end

function cast(
    route::Pair{A,B},
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T,A<:Sense,B<:Sense}
    L = cast(route, L̄)
    Q = cast(route, Q̄)

    return (L, Q, α, -β)
end

# -* Domain *- #
function cast(
    ::Pair{D,D},
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T,D<:Domain}
    L = copy(L̄)
    Q = copy(Q̄)

    return (L, Q, α, β)
end

function cast(
    ::Pair{SpinDomain,BoolDomain},
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    L = sizehint!(Dict{Int,T}(), length(L̄))
    Q = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q̄))

    for (i, c) in L̄
        L[i] = get(L, i, zero(T)) + 2c
        β    -= c
    end

    for ((i, j), c) in Q̄
        Q[(i, j)] = get(Q, (i, j), zero(T)) + 4c
        L[i]      = get(L, i, zero(T)) - 2c
        L[j]      = get(L, j, zero(T)) - 2c
        β         += c
    end

    return (L, Q, α, β)
end

function cast(
    ::Pair{BoolDomain,SpinDomain},
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    L = sizehint!(Dict{Int,T}(), length(L̄))
    Q = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q̄))

    for (i, c) in L̄
        L[i] = get(L, i, zero(T)) + c / 2
        β    += c / 2
    end

    for ((i, j), c) in Q̄
        Q[(i, j)] = get(Q, (i, j), zero(T)) + c / 4
        L[i]      = get(L, i, zero(T)) + c / 4
        L[j]      = get(L, j, zero(T)) + c / 4
        β         += c / 4
    end

    return (L, Q, α, β)
end
