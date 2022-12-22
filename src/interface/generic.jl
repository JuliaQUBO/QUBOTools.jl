function value(
    Q::AbstractMatrix{T},
    ψ::AbstractVector{U},
    α::T = one(T),
    β::T = zero(T),
) where {T<:Number,U<:Integer}
    return α * (ψ' * Q * ψ + β)
end

function value(
    h::AbstractVector{T},
    J::AbstractMatrix{T},
    ψ::AbstractVector{U},
    α::T = one(T),
    β::T = zero(T),
) where {T<:Number,U<:Integer}
    return α * (ψ' * J * ψ + h' * ψ + β)
end

function value(
    Q::Dict{Tuple{Int,Int},T},
    ψ::Vector{U},
    α::T = one(T),
    β::T = zero(T),
) where {T<:Number,U<:Integer}
    e = zero(T)

    for ((i, j), c) in Q
        e += ψ[i] * ψ[j] * c
    end

    return α * (e + β)
end

function value(
    h::Dict{Int,T},
    J::Dict{Tuple{Int,Int},T},
    ψ::Vector{U},
    α::T = one(T),
    β::T = zero(T),
) where {T<:Number,U<:Integer}
    e = zero(T)

    for (i, c) in h
        e += ψ[i] * c
    end

    for ((i, j), c) in J
        e += ψ[i] * ψ[j] * c
    end

    return α * (e + β)
end

function value(
    L::Vector{T},
    Q::Vector{T},
    u::Vector{Int},
    v::Vector{Int},
    ψ::Vector{U},
    α::T = one(T),
    β::T = zero(T),
) where {T<:Number,U<:Integer}
    e = zero(T)

    for i in eachindex(L)
        e += ψ[i] * L[i]
    end

    for k in eachindex(Q)
        e += ψ[u[k]] * ψ[v[k]] * Q[k]
    end

    return α * (e + β)
end

function adjacency(G::Vector{Tuple{Int,Int}})
    A = Dict{Int,Set{Int}}()

    for (i, j) in G
        if !haskey(A, i)
            A[i] = Set{Int}()
        end

        if i == j
            continue
        end

        if !haskey(A, j)
            A[j] = Set{Int}()
        end

        push!(A[i], j)
        push!(A[j], i)
    end

    return A
end

adjacency(G::Set{Tuple{Int,Int}})  = adjacency(collect(G))
adjacency(G::Dict{Tuple{Int,Int}}) = adjacency(collect(keys(G)))

function adjacency(G::Vector{Tuple{Int,Int}}, k::Integer)
    A = Set{Int}()

    for (i, j) in G
        if i == j
            continue
        end

        if i == k
            push!(A, j)
        end

        if j == k
            push!(A, i)
        end
    end

    return A
end

adjacency(G::Set{Tuple{Int,Int}}, k::Integer)  = adjacency(collect(G), k)
adjacency(G::Dict{Tuple{Int,Int}}, k::Integer) = adjacency(collect(keys(G)), k)

swap_sense(::Nothing)                              = nothing
swap_sense(s::Sense)                               = s === Min ? Max : Min
swap_sense(target::Symbol, x::Any)                 = swap_sense(Sense(target), x)
swap_sense(source::Symbol, target::Symbol, x::Any) = swap_sense(Sense(source), Sense(target), x)

function swap_sense(target::Sense, x::Any)
    return swap_sense(sense(x), target, x)
end

function swap_sense(source::Sense, target::Sense, x::Any)
    if source === target
        return x
    else
        return swap_sense(x)
    end
end

function swap_sense(L::Dict{Int,T}) where {T}
    return Dict{Int,T}(i => -c for (i, c) in L)
end

function swap_sense(Q::Dict{Tuple{Int,Int},T}) where {T}
    return Dict{Tuple{Int,Int},T}(ij => -c for (ij, c) in Q)
end

function swap_sense(source::Sense, target::Sense)
    if source === target
        return identity
    else
        return (x) -> swap_sense(x)
    end
end

function swap_domain(source::Domain, target::Domain)
    if source === target
        return identity
    else
        return (x) -> swap_domain(source, target, x)
    end
end

function format(source::AbstractModel, target::AbstractModel, data::Any)
    return format(sense(source), domain(source), sense(target), domain(target), data::Any)
end

function format(
    source_sense::Sense,
    source_domain::Domain,
    target_sense::Sense,
    target_domain::Domain,
    data::Any,
)
    return data |> (
        swap_sense(source_sense, target_sense) ∘ swap_domain(source_domain, target_domain)
    )
end