@doc raw"""
    DenseLinearForm{T}
"""
struct DenseLinearForm{T} <: AbstractLinearForm{T}
    data::Vector{T}
end

function DenseLinearForm(lf::DenseLinearForm{T}) where {T}
    return DenseLinearForm{T}(data(lf))
end

function DenseLinearForm{T}(n::Integer, lf::LF) where {T,S,LF<:AbstractLinearForm{S}}
    data = zeros(T, n)

    for (i, v) in linear_terms(lf)
        data[i] = convert(T, v)
    end

    return DenseLinearForm{T}(data)
end

function DenseLinearForm{T}(n::Integer, ::Integer) where {T}
    data = zeros(T, n)

    return DenseLinearForm{T}(data)
end

data(lf::DenseLinearForm) = lf.data

function linear_terms(lf::DenseLinearForm)
    L = data(lf)

    return (i => L[i] for i = eachindex(L) if !iszero(L[i]))
end

function linear_size(lf::DenseLinearForm)
    L = data(lf)

    return count(!iszero, L; init = 0)
end

function Base.getindex(lf::DenseLinearForm, i::Integer)
    return getindex(data(lf), i)
end

function Base.setindex!(lf::DenseLinearForm{T}, v::T, i::Integer) where {T}
    setindex!(data(lf), v, i)

    return v
end


@doc raw"""
    DenseQuadraticForm{T}
"""
struct DenseQuadraticForm{T} <: AbstractQuadraticForm{T}
    data::UpperTriangular{T,Matrix{T}}
end

function DenseQuadraticForm(qf::DenseQuadraticForm{T}) where {T}
    return DenseQuadraticForm{T}(data(qf))
end

function DenseQuadraticForm{T}(n::Integer, qf::QF) where {T,S,QF<:AbstractQuadraticForm{S}}
    data = UpperTriangular{T,Matrix{T}}(zeros(T, n, n))

    for ((i, j), v) in quadratic_terms(qf)
        data[i, j] = convert(T, v)
    end

    return DenseQuadraticForm{T}(data)
end

function DenseQuadraticForm{T}(n::Integer, ::Integer) where {T}
    data = UpperTriangular{T,Matrix{T}}(zeros(T, n, n))

    return DenseQuadraticForm{T}(data)
end

data(qf::DenseQuadraticForm) = qf.data

function quadratic_terms(qf::DenseQuadraticForm)
    Q = data(qf)
    n = size(Q, 1)

    return ((i, j) => Q[i, j] for i = 1:n for j = (i+1):n if !iszero(Q[i, j]))
end

function quadratic_size(qf::DenseQuadraticForm)
    Q = data(qf)

    return count(!iszero, Q; init = 0)
end


function Base.getindex(qf::DenseQuadraticForm, i::Integer, j::Integer)
    return getindex(data(qf), i, j)
end

function Base.setindex!(qf::DenseQuadraticForm{T}, v::T, i::Integer, j::Integer) where {T}
    setindex!(data(qf), v, i, j)

    return v
end

@doc raw"""
    DenseForm{T}

This QUBO form is built using a vector for the linear terms and a matrix for
storing the quadratic terms.
"""
const DenseForm{T} = Form{T,DenseLinearForm{T},DenseQuadraticForm{T}}

function DenseForm{T}(
    n::Integer,
    L::AbstractVector{T},
    Q::AbstractMatrix{T},
    α::T = one(T),
    β::T = zero(T);
    sense::Union{Symbol,Sense} = :min,
    domain::Union{Symbol,Domain} = :bool,
) where {T}
    l = zeros(T, n)
    q = UpperTriangular{T,Matrix{T}}(zeros(T, n, n))

    for i = 1:n
        l[i] = L[i] + Q[i, i]
    end

    for i = 1:n, j = (i+1):n
        q[i, j] = Q[i, j] + Q[j, i]
    end

    return Form{T}(n, DenseLinearForm{T}(l), DenseQuadraticForm{T}(q), α, β; sense, domain)
end


function formtype(::Val{:dense}, ::Type{T} = Float64) where {T}
    return DenseForm{T}
end

function formtype(::Type{Matrix}, ::Type{T} = Float64) where {T}
    return DenseForm{T}
end
