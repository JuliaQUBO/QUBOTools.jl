@doc raw"""
    SparseLinearForm{T}
"""
struct SparseLinearForm{T} <: AbstractLinearForm{T}
    data::SparseVector{T,Int}
end

function SparseLinearForm{T}(n::Integer, lf::LF) where {T,S,LF<:AbstractLinearForm{S}}
    data = spzeros(T, n)

    for (i, v) in linear_terms(lf)
        data[i] = convert(T, v)
    end

    return SparseLinearForm{T}(data)
end

function SparseLinearForm{T}(n::Integer, k::Integer) where {T}
    data = sizehint!(spzeros(T, n), k)

    return SparseLinearForm{T}(data)
end

data(lf::SparseLinearForm) = lf.data

function linear_terms(lf::SparseLinearForm)
    L = data(lf)

    return (i => v for (i, v) in zip(findnz(L)...))
end

function linear_size(lf::SparseLinearForm)
    L = data(lf)

    return nnz(L)
end


function Base.getindex(lf::SparseLinearForm, i::Integer)
    return getindex(data(lf), i)
end

function Base.setindex!(lf::SparseLinearForm{T}, v::T, i::Integer) where {T}
    setindex!(data(lf), v, i)
    
    return v
end


@doc raw"""
    SparseQuadraticForm{T}
"""
struct SparseQuadraticForm{T} <: AbstractQuadraticForm{T}
    data::SparseMatrixCSC{T,Int}
end

function SparseQuadraticForm{T}(n::Integer, qf::QF) where {T,S,QF<:AbstractQuadraticForm{S}}
    data = zeros(T, n, n)

    for ((i, j), v) in quadratic_terms(qf)
        data[i, j] = convert(T, v)
    end

    return SparseQuadraticForm{T}(data)
end

function SparseQuadraticForm{T}(n::Integer, k::Integer) where {T}
    data = sizehint!(spzeros(T, n, n), k)

    return SparseQuadraticForm{T}(data)
end

data(qf::SparseQuadraticForm) = qf.data

function quadratic_terms(qf::SparseQuadraticForm)
    Q = data(qf)

    return ((i, j) => v for (i, j, v) in zip(findnz(Q)...))
end

function quadratic_size(qf::SparseQuadraticForm)
    Q = data(qf)

    return nnz(Q)
end


function Base.getindex(qf::SparseQuadraticForm, i::Integer, j::Integer)
    return getindex(data(qf), i, j)
end

function Base.setindex!(qf::SparseQuadraticForm{T}, v::T, i::Integer, j::Integer) where {T}
    setindex!(data(qf), v, i, j)

    return v
end

@doc raw"""
    SparseForm{T}

This QUBO form is built using a sparse vector for the linear terms and a sparse
matrix for the quadratic ones.
"""
const SparseForm{T} = Form{T,SparseLinearForm{T},SparseQuadraticForm{T}}

function SparseForm{T}(
    n::Integer,
    L::AbstractVector{T},
    Q::AbstractMatrix{T},
    α::T = one(T),
    β::T = zero(T);
    sense::Union{Symbol,Sense} = :min,
    domain::Union{Symbol,Domain} = :bool,
) where {T}
    l = spzeros(T, n)
    q = spzeros(T, n, n)

    for i = 1:n
        if QUBOTools.domain(domain) === BoolDomain
            l[i] = L[i] + Q[i, i]
        else # QUBOTools.domain(domain) === SpinDomain
            l[i] = L[i]

            β += Q[i, i]
        end
    end

    for i = 1:n, j = (i+1):n
        q[i, j] = Q[i, j] + Q[j, i]
    end

    return Form{T}(n, SparseLinearForm{T}(l), SparseQuadraticForm{T}(q), α, β; sense, domain)
end


function formtype(::Val{:sparse}, ::Type{T} = Float64) where {T}
    return SparseForm{T}
end

function formtype(::Type{SparseMatrixCSC}, ::Type{T} = Float64) where {T}
    return SparseForm{T}
end
