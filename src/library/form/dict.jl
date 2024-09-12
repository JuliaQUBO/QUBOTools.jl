@doc raw"""
    DictLinearForm{T}
"""
struct DictLinearForm{T} <: AbstractLinearForm{T}
    data::Dict{Int,T}
end

function DictLinearForm(lf::DictLinearForm{T}) where {T}
    return DictLinearForm{T}(data(lf))
end

function DictLinearForm{T}(::Integer, lf::LF) where {T,S,LF<:AbstractLinearForm{S}}
    data = sizehint!(Dict{Int,T}(), linear_size(lf))

    for (i, v) in linear_terms(lf)
        data[i] = convert(T, v)
    end

    return DictLinearForm{T}(data)
end

function DictLinearForm{T}(::Integer, k::Integer) where {T}
    data = sizehint!(Dict{Int,T}(), k)

    return DictLinearForm{T}(data)
end

data(lf::DictLinearForm) = lf.data

function linear_terms(lf::DictLinearForm)
    return data(lf)
end

function linear_size(lf::DictLinearForm)
    L = data(lf)

    return length(L)
end

function Base.getindex(lf::DictLinearForm{T}, i::Integer) where {T}
    return get(data(lf), i, zero(T))
end

function Base.setindex!(lf::DictLinearForm{T}, v::T, i::Integer) where {T}
    if iszero(v)
        delete!(data(lf), i)
    else
        setindex!(data(lf), v, i)
    end

    return v
end


@doc raw"""
    DictQuadraticForm{T}
"""
struct DictQuadraticForm{T} <: AbstractQuadraticForm{T}
    data::Dict{Tuple{Int,Int},T}
end

function DictQuadraticForm(qf::DictQuadraticForm{T}) where {T}
    return DictQuadraticForm{T}(data(qf))
end

function DictQuadraticForm{T}(::Integer, qf::QF) where {T,S,QF<:AbstractQuadraticForm{S}}
    data = sizehint!(Dict{Tuple{Int,Int},T}(), quadratic_size(qf))

    for ((i, j), v) in quadratic_terms(qf)
        data[i, j] = convert(T, v)
    end

    return DictQuadraticForm{T}(data)
end

function DictQuadraticForm{T}(::Integer, k::Integer) where {T}
    data = sizehint!(Dict{Tuple{Int,Int},T}(), k)

    return DictQuadraticForm{T}(data)
end


data(qf::DictQuadraticForm) = qf.data

function quadratic_terms(qf::DictQuadraticForm)
    return data(qf)
end

function quadratic_size(qf::DictQuadraticForm)
    Q = data(qf)

    return length(Q)
end


function Base.getindex(qf::DictQuadraticForm{T}, i::Integer, j::Integer) where {T}
    @assert i < j

    return get(data(qf), (i, j), zero(T))
end

function Base.setindex!(qf::DictQuadraticForm{T}, v::T, i::Integer, j::Integer) where {T}
    @assert i < j

    if iszero(v)
        delete!(data(qf), (i, j))
    else
        setindex!(data(qf), v, i, j)
    end

    return v
end

@doc raw"""
    DictForm{T}

This QUBO form is built using dictionaries for both the linear and quadratic
terms.
"""
const DictForm{T} = Form{T,DictLinearForm{T},DictQuadraticForm{T}}

function DictForm{T}(
    n::Integer,
    L::Dict{Int,T},
    Q::Dict{Tuple{Int,Int},T},
    α::T = one(T),
    β::T = zero(T);
    sense::Union{Symbol,Sense} = :min,
    domain::Union{Symbol,Domain} = :bool,
) where {T}
    l = sizehint!(Dict{Int,T}(), length(L))
    q = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q))

    for (i, v) in L
        iszero(v) && continue

        l[i] = get(l, i, zero(T)) + v

        iszero(l[i]) && delete!(l, i)
    end

    for ((i, j), v) in Q
        iszero(v) && continue

        if i == j
            if QUBOTools.domain(domain) === BoolDomain
                l[i] = get(l, i, zero(T)) + v

                iszero(l[i]) && delete!(l, i)
            else # QUBOTools.domain(domain) === SpinDomain
                β += v
            end
        elseif i > j
            q[(j, i)] = get(q, (j, i), zero(T)) + v

            iszero(q[(j, i)]) && delete!(q, (j, i))
        else # i < j
            q[(i, j)] = get(q, (i, j), zero(T)) + v

            iszero(q[(i, j)]) && delete!(q, (i, j))
        end
    end

    return Form{T}(n, DictLinearForm{T}(l), DictQuadraticForm{T}(q), α, β; sense, domain)
end


function formtype(::Val{:dict}, ::Type{T} = Float64) where {T}
    return DictForm{T}
end

function formtype(::Type{Dict}, ::Type{T} = Float64) where {T}
    return DictForm{T}
end
