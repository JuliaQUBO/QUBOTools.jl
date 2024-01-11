function Base.copy(L::LF) where {LF<:AbstractLinearForm}
    return LF(copy(data(L)))
end

function Base.copy(Q::QF) where {QF<:AbstractQuadraticForm}
    return QF(copy(data(Q)))
end

function linear_size(Φ::F) where {T,F<:AbstractForm{T}}
    return linear_size(linear_form(Φ))
end

function linear_terms(Φ::F) where {T,F<:AbstractForm{T}}
    return linear_terms(linear_form(Φ))
end


function quadratic_size(Φ::F) where {T,F<:AbstractForm{T}}
    return quadratic_size(quadratic_form(Φ))
end

function quadratic_terms(Φ::F) where {T,F<:AbstractForm{T}}
    return quadratic_terms(quadratic_form(Φ))
end


function topology(Φ::F) where {T,F<:AbstractForm{T}}
    E = Graphs.Edge{Int}[]

    for t in quadratic_terms(Φ)
        i, j = first(t)

        push!(E, Graphs.Edge{Int}(i, j))
    end

    return Graphs.Graph(E)
end


function value(ψ::State{U}, Φ::F) where {T,U,F<:AbstractForm{T}}
    L = data(linear_form(Φ))
    Q = data(quadratic_form(Φ))
    α = scale(Φ)
    β = offset(Φ)

    return value(ψ, L, Q, α, β)
end

function value(ψ::State{U}, L, Q, α::T = one(T), β::T = zero(T)) where {T,U}
    return α * (value(ψ, L) + value(ψ, Q) + β)
end

function value(ψ::State{U}, L::AbstractVector{T}) where {T,U}
    return L' * ψ
end

function value(ψ::State{U}, Q::AbstractMatrix{T}) where {T,U}
    return ψ' * Q * ψ
end

function value(ψ::State{U}, L::AbstractDict{Int,T}) where {T,U}
    s = zero(T)

    for (i, v) in L
        s += ψ[i] * v
    end

    return s
end

function value(ψ::State{U}, Q::AbstractDict{Tuple{Int,Int},T}) where {T,U}
    s = zero(T)

    for ((i, j), v) in Q
        s += ψ[i] * ψ[j] * v
    end

    return s
end

function cast(t::Sense, Φ::F) where {T,F<:AbstractForm{T}}
    return cast((sense(Φ) => t), Φ)
end

function cast(t::Domain, Φ::F) where {T,F<:AbstractForm{T}}
    return cast((domain(Φ) => t), Φ)
end


function form(
    src::AbstractModel{V,T,U},
    ::Type{F};
    sense::Union{Sense,Symbol}   = QUBOTools.sense(src),
    domain::Union{Domain,Symbol} = QUBOTools.domain(src),
) where {V,T,U,F<:AbstractForm{T}}
    return F(cast(frame(src) => Frame(sense, domain), form(src)))
end

function form(
    src::AbstractModel{V,T,U},
    spec::Symbol,
    type::Type = T;
    sense::Union{Sense,Symbol} = QUBOTools.sense(src),
    domain::Union{Domain,Symbol} = QUBOTools.domain(src),
) where {V,T,U}
    return form(src, formtype(spec, type); sense, domain)
end


function formtype(spec::Symbol, ::Type{T} = Float64) where {T}
    return formtype(Val(spec), T)
end

function formtype(::Val{spec}, ::Type = Float64) where {spec}
    error("Unknown form type specifier '$(spec)'")
end

function formtype(::Type{spec}, ::Type = Float64) where {spec}
    error("Unknown form type specifier '$(spec)'")
end


function qubo(src::AbstractModel{V,T,U}, args...; kws...) where {V,T,U}
    return form(src, args...; kws..., domain = :bool)
end

function ising(src::AbstractModel{V,T,U}, args...; kws...) where {V,T,U}
    return form(src, args...; kws..., domain = :spin)
end


# Adding an iterate interface allows struct unpacking, i.e.,
# n, L, Q, α, β, sense, domain = form
Base.length(::F) where {T,F<:AbstractForm{T}} = 7

function Base.iterate(Φ::F, state::Integer = 1) where {T,F<:AbstractForm{T}}
    if state == 1
        return (dimension(Φ), state + 1)
    elseif state == 2
        return (data(linear_form(Φ)), state + 1)
    elseif state == 3
        return (data(quadratic_form(Φ)), state + 1)
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

