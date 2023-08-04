struct SampleModel{T} end

struct QUBOModel{V,T,U} <: QUBOTools.AbstractModel{V,T,U} end

value(::SampleModel{T}, ::Any) where {T} = zero(T)

function test_samples()
    # Assets
    ψ = [↑, ↓, ↑]
    Ψ = [0, 1, 0]
    ϕ = [↓, ↑, ↓]
    Φ = [1, 0, 1]


    
end