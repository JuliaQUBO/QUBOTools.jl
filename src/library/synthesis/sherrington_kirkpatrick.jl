@doc raw"""
    SherringtonKirkpatrick{T}(n::Integer, μ::T, σ::T)

Generates a Sherrington-Kirkpatrick model in ``n`` variables.
Coefficients are normally distributed with mean ``\mu`` and variance ``\sigma``.
"""
struct SherringtonKirkpatrick{T} <: AbstractProblem{T}
    n::Int
    μ::T
    σ::T

    function SherringtonKirkpatrick{T}(n::Integer, μ::T = zero(T), σ::T = one(T)) where {T}
        return new{T}(n, μ, σ)
    end
end

function SherringtonKirkpatrick(n::Integer, μ::Float64 = 0.0, σ::Float64 = 1.0)
    return SherringtonKirkpatrick{Float64}(n, μ, σ)
end

const SK{T} = SherringtonKirkpatrick{T}

function generate(rng, problem::SherringtonKirkpatrick{T}) where {T}
    f, x = PBO.sherrington_kirkpatrick(
        rng,
        PBO.PBF{Int,T},
        problem.n;
        μ = problem.μ,
        σ = problem.σ,
    )

    model = Model{Int,Float64,Int}(
        f;
        metadata = Dict{String,Any}(
            "origin"    => "Generated using QUBOTools.jl",
            "synthesis" => Dict{String,Any}(
                "model"      => "Sherrington-Kirkpatrick",
                "parameters" => Dict{String,Any}(
                    "n"     => problem.n,
                    "mu"    => problem.μ,
                    "sigma" => problem.σ,
                ),
            ),
        )
    )

    if !isnothing(x)
        sol = SampleSet{T,Int}(
            model, x;
            metadata = Dict{String,Any}(
                "origin" => "Planted",
                "status" => "optimal",
                "time"   => Dict{String,Any}(
                    "total"     => NaN,
                    "effective" => NaN,
                ),
            )
        )

        attach!(model, sol)
    end

    return model
end
