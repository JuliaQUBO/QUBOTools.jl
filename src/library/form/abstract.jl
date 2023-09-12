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

function topology(Φ::F, k::Integer) where {T,F<:AbstractForm{T}}
    N = Set{Int}()

    for ((i, j), _) in quadratic_terms(Φ)
        if i == k
            push!(N, j)
        elseif j == k
            push!(N, i)
        end
    end

    return N
end


function value(Φ::F, ψ::State{U}) where {T,U,F<:AbstractForm{T}}
    L = linear_form(Φ)
    Q = quadratic_form(Φ)
    α = scale(Φ)
    β = offset(Φ)

    return α * (value(L, ψ) + value(Q, ψ) + β)
end

function value(lf::LF, ψ::State{U}) where {T,U,LF<:AbstractLinearForm{T}}
    return value(data(lf), ψ)
end

function value(qf::QF, ψ::State{U}) where {T,U,QF<:AbstractQuadraticForm{T}}
    return value(data(qf), ψ)
end

function value(L::AbstractVector{T}, ψ::State{U}) where {T,U}
    return L' * ψ
end

function value(Q::AbstractMatrix{T}, ψ::State{U}) where {T,U}
    return ψ' * Q * ψ
end

function value(L::AbstractDict{Int,T}, ψ::State{U}) where {T,U}
    s = zero(T)

    for (i, v) in L
        s += ψ[i] * v
    end

    return s
end

function value(Q::AbstractDict{Tuple{Int,Int},T}, ψ::State{U}) where {T,U}
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
    type::Symbol;
    sense::Union{Sense,Symbol}   = QUBOTools.sense(src),
    domain::Union{Domain,Symbol} = QUBOTools.domain(src),
) where {V,T,U}
    return form(src, formtype(Val(type), T); sense, domain)
end

function formtype(::Val{type}) where {type}
    error("Unknown form type specifier '$(type)'.")

    return nothing
end

function formtype(::Type{type}) where {type}
    error("Unknown form type specifier '$(type)'.")

    return nothing
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

