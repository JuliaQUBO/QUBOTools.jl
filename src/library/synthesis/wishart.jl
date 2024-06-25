@doc raw"""
    Wishart{T}(n::Integer, m::Integer)

Represents the Wishart model on ``n`` variables whose ``\mathbf{W}`` matrix has
``m`` columns.

When `true`, the `discretize` keyword limits the entries of the ``\mathbf{R}``
matrix to ``\pm 1``.
The `precision`, on the other hand, is the amount of digits to round each entry
``R_{i,j}`` after sampling from a normal distribution ``\mathcal{N}(0, 1)``.
"""
struct Wishart{T} <: AbstractProblem{T}
    n::Int
    m::Int

    discretize::Bool
    precision::Int

    function Wishart{T}(
        n::Integer,
        m::Integer;
        discretize::Bool = false,
        precision::Integer = 0,
    ) where {T}
        @assert precision >= 0

        return new{T}(n, m, discretize, precision)
    end
end

function Wishart(n::Integer, m::Integer; discretize::Bool = false, precision::Integer = 0)
    return Wishart{Float64}(n, m; discretize, precision)
end

function generate(rng, problem::Wishart{T}) where {T}
    f, x = PBO.wishart(
        rng,
        PBO.PBF{Int,T},
        problem.n,
        problem.m;
        discretize_bonds = problem.discretize,
        precision        = problem.precision,
    )

    model = Model{Int,T,Int}(
        f;
        metadata = Dict{String,Any}(
            "origin"    => "Generated by QUBOTools.jl",
            "synthesis" => Dict{String,Any}( # TODO: Add this to the Schema
                "model"      => "Wishart",
                "parameters" => Dict{String,Any}(
                    "n" => problem.n,
                    "m" => problem.m,
                )
            ),
        ),
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