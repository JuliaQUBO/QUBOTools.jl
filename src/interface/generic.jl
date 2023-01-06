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

function format(source::AbstractModel, target::AbstractModel, data::Any)
    return format(sense(source), domain(source), sense(target), domain(target), data)
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

# -* Sense *- #
swap_sense(::Nothing) = nothing

swap_sense(::MaxSense) = Min
swap_sense(::MinSense) = Max

function swap_sense(target::Symbol, x::Any)                
    return swap_sense(Sense(target), x)
end

function swap_sense(source::Symbol, target::Symbol, x::Any)
    return swap_sense(Sense(source), Sense(target), x)
end

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

# -* Format *- #
function format_types()
    return subtypes(AbstractFormat)
end

function formats()
    return [
        fmt(dom, sty)
        for fmt in format_types()
        for dom in domains()
        for sty in styles()
        if supports_domain(fmt, dom) && supports_style(fmt, sty)
    ]
end

function infer_format(path::AbstractString)
    pieces = reverse(split(basename(path), "."))

    if length(pieces) == 1
        format_error("Unable to infer QUBO format from file without an extension")
    else
        format_hint, domain_hint, _... = pieces
    end

    return infer_format(Symbol(domain_hint), Symbol(format_hint))
end

function infer_format(domain_hint::Symbol, format_hint::Symbol)
    return infer_format(Val(domain_hint), Val(format_hint))
end

function infer_format(::Val, format_hint::Val)
    return infer_format(format_hint)
end

function infer_format(format_hint::Symbol)
    return infer_format(Val(format_hint))
end


# -* Domain *- #
function domain_name(::BoolDomain)
    return "Bool"
end

function domain_name(::SpinDomain)
    return "Spin"
end

function domain_types()
    return Type[Nothing; subtypes(Domain)]
end

function domains()
    return Union{Domain,Nothing}[dom() for dom in domain_types()]
end

function supports_domain(::Type{F}, ::Nothing) where {F<:AbstractFormat}
    return false
end

function supports_domain(::Type{F}, ::Domain) where {F<:AbstractFormat}
    return false
end

function swap_domain(source::Domain, target::Domain)
    if source === target
        return identity
    else
        return (x) -> swap_domain(source, target, x)
    end
end

# -* Style *- #
function supports_style(::Type{F}, ::Nothing) where {F<:AbstractFormat}
    return true
end

function supports_style(::Type{F}, ::Style) where {F<:AbstractFormat}
    return false
end

function style_types()
    return Type[Nothing; subtypes(Style)]
end

function styles()
    return Union{Style,Nothing}[sty() for sty in style_types()]
end

function style(::AbstractFormat)
    return nothing
end

# -* I/O *- #
function Base.show(io::IO, fmt::F) where {F<:AbstractFormat}
    return print(io, "$F($(domain(fmt)),$(style(fmt)))")
end

function read_model(path::AbstractString, fmt::AbstractFormat = infer_format(path))
    return open(path, "r") do fp
        return read_model(fp, fmt)
    end
end

function read_model!(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = infer_format(path))
    return open(path, "r") do fp
        return read_model!(fp, model, fmt)
    end
end

function read_model!(io::IO, model::AbstractModel, fmt::AbstractFormat)
    return copy!(model, read_model(io, fmt))
end

function write_model(path::AbstractString, model::AbstractModel, fmt::AbstractFormat = infer_format(path))
    open(path, "w") do fp
        write_model(fp, model, fmt)
    end
end
