name(::M) where {M<:AbstractModel} = "QUBO Model"

Base.isempty(model::AbstractModel) = isempty(variable_map(model))

function explicit_linear_terms(model::AbstractModel{V,T}) where {V,T}
    L = linear_terms(model)

    return Dict{Int,T}(i => get(L, i, zero(T)) for i = 1:domain_size(model))
end

function indices(model::AbstractModel)
    return collect(1:domain_size(model))
end

function variables(model::AbstractModel{V,T}) where {V,T}
    return V[variable_inv(model, i) for i = 1:domain_size(model)]
end

function variable_set(model::AbstractModel{V,T}) where {V,T}
    return Set{V}(keys(variable_map(model)))
end

function variable_map(model::AbstractModel{V,T}, v::V) where {V,T}
    mapping = variable_map(model)

    if haskey(mapping, v)
        return mapping[v]
    else
        error("Variable '$v' does not belong to the model")

        return nothing
    end
end

function variable_inv(model::AbstractModel, i::Integer)
    mapping = variable_inv(model)

    if haskey(mapping, i)
        return mapping[i]
    else
        error("Variable index '$i' does not belong to the model")

        return nothing
    end
end

function warm_start(model::AbstractModel{V,T}, v::V) where {V,T}
    return get(warm_start(model), v, nothing)
end

# ~*~ Model's Normal Forms ~*~ #
function qubo(model::AbstractModel, type::Type = Dict)
    n = domain_size(model)

    L, Q, α, β = cast(
        domain(model) => 𝔹,
        linear_terms(model),
        quadratic_terms(model),
        scale(model),
        offset(model),
    )

    return qubo(type, n, L, Q, α, β)
end

function qubo(
    ::Type{Dict},
    ::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    Q = sizehint!(Dict{Tuple{Int,Int},T}(), length(L̄) + length(Q̄))

    for (i, qi) in L̄
        Q[i, i] = qi
    end

    for ((i, j), Qij) in Q̄
        Q[i, j] = Qij
    end

    return (Q, α, β)
end

function qubo(
    ::Type{Vector},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    L = zeros(T, n)
    Q = Vector{T}(undef, length(Q̄))
    u = Vector{Int}(undef, length(Q̄))
    v = Vector{Int}(undef, length(Q̄))

    for (i, c) in L̄
        L[i] = c
    end

    for (k, ((i, j), c)) in enumerate(Q̄)
        Q[k] = c
        u[k] = i
        v[k] = j
    end

    return (L, Q, u, v, α, β)
end

function qubo(
    ::Type{Matrix},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    Q = zeros(T, n, n)

    for (i, c) in L̄
        Q[i, i] = c
    end

    for ((i, j), c) in Q̄
        Q[i, j] = c
    end

    return (Q, α, β)
end

function qubo(
    ::Type{Symmetric},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    Q = zeros(T, n, n)

    for (i, c) in L̄
        Q[i, i] = c
    end

    for ((i, j), c) in Q̄
        Q[i, j] = c / 2
    end

    return (Symmetric(Q), α, β)
end

function qubo(
    ::Type{SparseMatrixCSC},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    Q = spzeros(T, n, n)

    for (i, c) in L̄
        Q[i, i] = c
    end

    for ((i, j), c) in Q̄
        Q[i, j] = c
    end

    return (Q, α, β)
end

function ising(model::AbstractModel, type::Type = Dict)
    n = domain_size(model)

    L, Q, α, β = cast(
        domain(model) => Domain(:spin),
        linear_terms(model),
        quadratic_terms(model),
        scale(model),
        offset(model),
    )

    return ising(type, n, L, Q, α, β)
end

function ising(
    ::Type{Dict},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    h = sizehint!(Dict{Int,T}(), length(L̄))
    J = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q̄))

    for (i, c) in L̄
        h[i] = c
    end

    for ((i, j), c) in Q̄
        J[i, j] = c
    end

    return (h, J, α, β)
end

function ising(
    ::Type{Vector},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    h = zeros(T, n)
    J = Vector{T}(undef, length(Q̄))
    u = Vector{Int}(undef, length(Q̄))
    v = Vector{Int}(undef, length(Q̄))

    for (i, c) in L̄
        h[i] = c
    end

    for (k, ((i, j), c)) in enumerate(Q̄)
        J[k] = c
        u[k] = i
        v[k] = j
    end

    return (h, J, u, v, α, β)
end

function ising(
    ::Type{Matrix},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    h = zeros(T, n)
    J = zeros(T, n, n)

    for (i, c) in L̄
        h[i] = c
    end

    for ((i, j), c) in Q̄
        J[i, j] = c
    end

    return (h, J, α, β)
end

function ising(
    ::Type{Symmetric},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    h = zeros(T, n)
    J = zeros(T, n, n)

    for (i, c) in L̄
        h[i] = c
    end

    for ((i, j), c) in Q̄
        J[i, j] = c / 2
    end

    return (h, Symmetric(J), α, β)
end

function ising(
    ::Type{SparseMatrixCSC},
    n::Integer,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
) where {T}
    h = spzeros(T, n)
    J = spzeros(T, n, n)

    for (i, c) in L̄
        h[i] = c
    end

    for ((i, j), c) in Q̄
        J[i, j] = c
    end

    return (h, J, α, β)
end

# ~*~ Data queries ~*~ #
function state(model::AbstractModel, index::Integer)
    return state(sampleset(model), index)
end

function reads(model::AbstractModel)
    return reads(sampleset(model))
end

function reads(model::AbstractModel, index::Integer)
    return reads(sampleset(model), index)
end

function value(model::AbstractModel, index::Integer)
    return value(sampleset(model), index)
end

function value(model::AbstractModel, ψ::Vector{U}) where {U<:Integer}
    α = scale(model)
    e = offset(model)

    for (i, l) in linear_terms(model)
        e += ψ[i] * l
    end

    for ((i, j), q) in quadratic_terms(model)
        e += ψ[i] * ψ[j] * q
    end

    return α * e
end

# ~*~ Queries: sizes & density ~*~ #
domain_size(model::AbstractModel)    = length(variable_map(model))
linear_size(model::AbstractModel)    = length(linear_terms(model))
quadratic_size(model::AbstractModel) = length(quadratic_terms(model))

function density(model::AbstractModel)
    n = domain_size(model)

    if n == 0
        return NaN
    else
        ls = linear_size(model)
        qs = quadratic_size(model)

        return (2 * qs + ls) / (n * n)
    end
end

function linear_density(model::AbstractModel)
    n = domain_size(model)

    if n == 0
        return NaN
    else
        ls = linear_size(model)

        return ls / n
    end
end

function quadratic_density(model::AbstractModel)
    n = domain_size(model)

    if n <= 1
        return NaN
    else
        qs = quadratic_size(model)

        return (2 * qs) / (n * (n - 1))
    end
end

function adjacency(model::AbstractModel)
    n = domain_size(model)
    A = Dict{Int,Set{Int}}(i => Set{Int}() for i = 1:n)

    for (i, j) in keys(quadratic_terms(model))
        push!(A[i], j)
        push!(A[j], i)
    end

    return A
end

function adjacency(model::AbstractModel, k::Integer)
    A = Set{Int}()

    for (i, j) in keys(quadratic_terms(model))
        if i == k
            push!(A, j)
        elseif j == k
            push!(A, i)
        end
    end

    return A
end

# ~*~ I/O ~*~ #
function Base.read(source::Union{IO,AbstractString}, fmt::AbstractFormat)
    return read_model(source, fmt)
end

function Base.read!(
    source::Union{IO,AbstractString},
    model::AbstractModel,
    fmt::AbstractFormat,
)
    return read_model!(source, model, fmt)
end

function Base.write(
    target::Union{IO,AbstractString},
    model::AbstractModel,
    fmt::AbstractFormat,
)
    return write_model(target, model, fmt)
end

function Base.copy!(target::X, source::Y) where {X<:AbstractModel,Y<:AbstractModel}
    return copy!(target, convert(X, source))
end

function Base.show(io::IO, model::AbstractModel)
    println(
        io,
        """
        $(name(model)) [$(sense(model)), $(domain(model))]
        ▷ Variables ……… $(domain_size(model))  
        """,
    )

    if isempty(model)
        println(
            io,
            """
            The model is empty.
            """,
        )

        return nothing
    else
        println(
            io,
            """
            Density:
            ▷ Linear ……………… $(@sprintf("%0.2f", 100.0 * linear_density(model)))%
            ▷ Quadratic ……… $(@sprintf("%0.2f", 100.0 * quadratic_density(model)))%
            ▷ Total ………………… $(@sprintf("%0.2f", 100.0 * density(model)))%
            """,
        )
    end

    if isempty(sampleset(model))
        print(
            io,
            """
            There are no solutions available.
            """,
        )

        return nothing
    else
        ω = sampleset(model)
        n = length(ω)
        z = sense(model) === Min ? value(ω[begin]) : value(ω[end])

        print(
            io,
            """
            Solutions:
            ▷ Samples …………… $(n)
            ▷ Best value …… $(z)
            """,
        )
    end

    return nothing
end

# -* Casting Fallback *- #
function cast(target::Sense, model::AbstractModel)
    return cast(sense(model) => target, model)
end

function cast(target::Domain, model::AbstractModel)
    return cast(domain(model) => target, model)
end