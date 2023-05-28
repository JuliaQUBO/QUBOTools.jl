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

# -* Format *- #
include("format.jl")

# -* Domain/Sense Casting *- #
include("cast.jl")

# -* I/O *- #
function read_model(path::AbstractString, fmt::AbstractFormat = infer_format(path))
    return open(path, "r") do fp
        return read_model(fp, fmt)
    end
end

function Base.read(path::AbstractString, fmt::AbstractFormat)
    return read_model(path, fmt)
end

function read_model!(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = infer_format(path))
    return open(path, "r") do fp
        return read_model!(fp, model, fmt)
    end
end

function read_model!(io::IO, model::AbstractModel, fmt::AbstractFormat)
    return copy!(model, read_model(io, fmt))
end

function Base.read!(path::AbstractString, model::AbstractModel, fmt::AbstractFormat)
    return read_model!(path, model, fmt)
end

function write_model(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = infer_format(path))
    open(path, "w") do fp
        write_model(fp, model, fmt)
    end
end

function Base.write(path::AbstractString, model::AbstractModel, fmt::AbstractFormat)
    return write_model(path, model, fmt)
end
