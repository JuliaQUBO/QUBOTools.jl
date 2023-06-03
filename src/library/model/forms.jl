const LinearForm{T}    = SparseVector{T}
const QuadraticForm{T} = UpperTriangular{T,SparseMatrixCSC{T}}

struct NormalForm{T}
    n::Int
    L::LinearForm{T}
    Q::QuadraticForm{T}
    α::T
    β::T

    function NormalForm{T}(
        n::Integer,
        L::LinearForm{T},
        Q::QuadraticForm{T},
        α::T = one(T),
        β::T = zero(T),
    ) where {T}
        @assert size(L) == (n,)
        @assert size(Q) == (n, n)
        @assert α > zero(T)

        return new{T}(n, L, Q, α, β)
    end
end