# -* Sense *- #
function cast(::S, ::S, L̄::Dict{Int,T}) where {S<:Sense,T}
    return copy(L̄)
end

function cast(::Sense, ::Sense, L̄::Dict{Int,T}) where {T}
    L = sizehint!(Dict{Int,T}(), length(L̄))

    for (i, c) in L̄
        L[i] = -c
    end

    return L
end

function cast(::S, ::S, Q̄::Dict{Tuple{Int,Int},T}) where {S<:Sense,T}
    return copy(Q̄)
end

function cast(::Sense, ::Sense, Q̄::Dict{Tuple{Int,Int},T}) where {T}
    Q = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q̄))

    for (ij, c) in Q̄
        Q[ij] = -c
    end

    return Q
end

function cast(
    ::S,
    ::S,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {S<:Sense,T}
    L = copy(L̄)
    Q = copy(Q̄)

    return (L, Q, α, β)
end

function cast(
    source::Sense,
    target::Sense,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    L = cast(source, target, L̄)
    Q = cast(source, target, Q̄)

    return (L, Q, α, -β)
end

# -* Domain *- #
function cast(
    ::D,
    ::D,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {D<:Domain,T}
    L = copy(L̄)
    Q = copy(Q̄)

    return (L, Q, α, β)
end

function cast(
    ::SpinDomain,
    ::BoolDomain,
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
    ::BoolDomain,
    ::SpinDomain,
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


# -* Model *- #
function cast(source::AbstractModel, target::AbstractModel, data)
    return cast(sense(source), sense(target), domain(source), domain(target), data)
end

# -* Chain *- #
function cast(
    source_sense::Sense,
    target_sense::Sense,
    source_domain::Domain,
    target_domain::Domain,
    data,
)
    return cast(source_sense, target_sense, cast(source_domain, target_domain, data))
end
