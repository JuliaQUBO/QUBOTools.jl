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

function qubo(
    h::Dict{Int,T},
    J::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    Q = Dict{Tuple{Int,Int},T}()

    sizehint!(Q, length(h) + length(J))

    for (i, l) in h
        β -= l
        Q[(i, i)] = get(Q, (i, i), zero(T)) + 2l
    end

    for ((i, j), q) in J
        β += q
        Q[(i, j)] = get(Q, (i, j), zero(T)) + 4q
        Q[(i, i)] = get(Q, (i, i), zero(T)) - 2q
        Q[(j, j)] = get(Q, (j, j), zero(T)) - 2q
    end

    return (Q, α, β)
end

function qubo(
    h::Vector{T},
    J::Vector{T},
    u::Vector{Int},
    v::Vector{Int},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    n = length(h)
    m = length(J)
    L = zeros(T, n)
    Q = zeros(T, m)

    for i = 1:n
        l = h[i]

        β    -= l
        L[i] += 2l
    end

    for k = 1:m
        i = u[k]
        j = v[k]
        q = J[k]

        β    += q
        L[i] -= 2q
        L[j] -= 2q
        Q[k] += 4q
    end

    return (L, Q, u, v, α, β)
end

function qubo(h::Vector{T}, J::Matrix{T}, α::T = one(T), β::T = zero(T)) where {T}
    n = length(h)
    Q = zeros(T, n, n)

    for i = 1:n, j = i:n
        if i == j
            l = h[i]

            β       -= l
            Q[i, i] += 2l
        else
            q = J[i, j]

            β       += q
            Q[i, i] -= 2q
            Q[j, j] -= 2q
            Q[i, j] += 4q
        end
    end

    return (Q, α, β)
end

function qubo(
    h::SparseVector{T},
    J::SparseMatrixCSC{T},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    n = length(h)
    Q = spzeros(T, n, n)

    for i = 1:n, j = i:n
        if i == j
            l = h[i]

            β       -= l
            Q[i, i] += 2l
        else
            q = J[i, j]

            β       += q
            Q[i, j] += 4q
            Q[i, i] -= 2q
            Q[j, j] -= 2q
        end
    end

    return (Q, α, β)
end

function ising(Q::Dict{Tuple{Int,Int},T}, α::T = one(T), β::T = zero(T)) where {T}
    h = Dict{Int,T}()
    J = Dict{Tuple{Int,Int},T}()

    for ((i, j), q) in Q
        if i == j
            β    += q / 2
            h[i] = get(h, i, zero(T)) + q / 2
        else # i < j
            β         += q / 4
            h[i]      = get(h, i, zero(T)) + q / 4
            h[j]      = get(h, j, zero(T)) + q / 4
            J[(i, j)] = get(J, (i, j), zero(T)) + q / 4
        end
    end

    return (h, J, α, β)
end

function ising(
    L::Vector{T},
    Q::Vector{T},
    u::Vector{Int},
    v::Vector{Int},
    α::T = one(T),
    β::T = zero(T),
) where {T}
    n = length(L)
    m = length(Q)

    h = zeros(T, n)
    J = zeros(T, m)

    for i = 1:n
        l = L[i]

        β    += l / 2
        h[i] += l / 2
    end

    for k = 1:m
        i = u[k]
        j = v[k]
        q = Q[k]

        β    += q / 4
        h[i] += q / 4
        h[j] += q / 4
        J[k] += q / 4
    end

    return (h, J, u, v, α, β)
end

function ising(Q::Matrix{T}, α::T = one(T), β::T = zero(T)) where {T}
    n = size(Q, 1)

    h = zeros(T, n)
    J = zeros(T, n, n)

    for i = 1:n, j = i:n
        q = Q[i, j]

        if i == j
            β    += q / 2
            h[i] += q / 2
        else
            β       += q / 4
            h[i]    += q / 4
            h[j]    += q / 4
            J[i, j] += q / 4
        end
    end

    return (h, J, α, β)
end

function ising(Q::SparseMatrixCSC{T}, α::T = one(T), β::T = zero(T)) where {T}
    n = size(Q, 1)

    h = spzeros(T, n)
    J = spzeros(T, n, n)

    for i = 1:n, j = i:n
        q = Q[i, j]

        if i == j
            β    += q / 2
            h[i] += q / 2
        else
            β       += q / 4
            h[i]    += q / 4
            h[j]    += q / 4
            J[i, j] += q / 4
        end
    end

    return (h, J, α, β)
end
