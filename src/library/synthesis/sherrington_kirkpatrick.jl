@doc raw"""
    SherringtonKirkpatrick{T}(n::Integer, μ::Real = zero(T), σ::Real = one(T);
        normalize::Bool = false, gauge_invariant::Bool = true)

Generates a Sherrington-Kirkpatrick model in ``n`` variables with Gaussian couplings
``J_{i, j} \sim \mathcal{N}(\mu, \sigma^2)`` (scaled by ``1 / \sqrt{n}`` when
`normalize = true` and ``n > 0``).

When `gauge_invariant = true` (default), generates the zero-field ``\mathbb{Z}_2``
gauge-invariant QUBO with ``L_i = -\frac{1}{2} \sum_{j \neq i} Q_{i, j}`` and
offset ``\beta = \sum_{i < j} J_{i, j}`` so that ``h_i = 0`` for all ``i``.
When `gauge_invariant = false`, omits the linear and constant terms so the QUBO
has ``L_i = 0`` and ``\beta = 0``, inducing coercive local fields
``h_i = \frac{1}{4} \sum_{j \neq i} Q_{i, j}``.
"""
struct SherringtonKirkpatrick{T} <: AbstractProblem{T}
    n::Int
    μ::T
    σ::T
    normalize::Bool
    gauge_invariant::Bool

    function SherringtonKirkpatrick{T}(
        n::Integer,
        μ::Real = zero(T),
        σ::Real = one(T);
        normalize::Bool = false,
        gauge_invariant::Bool = true,
    ) where {T}
        n >= 0 || throw(ArgumentError("number of variables n must be nonnegative; got $n"))
        return new{T}(Int(n), convert(T, μ), convert(T, σ), normalize, gauge_invariant)
    end
end

function SherringtonKirkpatrick(
    n::Integer,
    μ::Real = 0.0,
    σ::Real = 1.0;
    normalize::Bool = false,
    gauge_invariant::Bool = true,
)
    T = promote_type(Float64, typeof(μ), typeof(σ))
    return SherringtonKirkpatrick{T}(n, μ, σ; normalize, gauge_invariant)
end

const SK{T} = SherringtonKirkpatrick{T}

function generate(rng, problem::SherringtonKirkpatrick{T}) where {T}
    @_deprecate_generate()

    eff_scale = (problem.normalize && problem.n > 0) ? convert(T, inv(sqrt(problem.n))) : one(T)

    f, x = PBO.sherrington_kirkpatrick(
        rng,
        PBO.PBF{Int,T},
        problem.n;
        μ = eff_scale * problem.μ,
        σ = eff_scale * problem.σ,
    )

    L = Dict{Int,T}()
    Q = Dict{Tuple{Int,Int},T}()
    β = zero(T)

    for (ω, c) in f
        if length(ω) == 0
            if problem.gauge_invariant
                β += c
            end
        elseif length(ω) == 1
            if problem.gauge_invariant
                i, = ω
                L[i] = get(L, i, zero(T)) + c
            end
        elseif length(ω) == 2
            i, j = ω
            Q[(i, j)] = get(Q, (i, j), zero(T)) + c
        end
    end

    model = Model{Int,T,Int}(
        Set{Int}(1:problem.n),
        L,
        Q;
        offset = β,
        sense = :min,
        domain = :bool,
        metadata = Dict{String,Any}(
            "origin"    => "Generated using QUBOTools.jl",
            "synthesis" => Dict{String,Any}(
                "model"      => "Sherrington-Kirkpatrick",
                "parameters" => Dict{String,Any}(
                    "n"               => problem.n,
                    "mu"              => problem.μ,
                    "sigma"           => problem.σ,
                    "normalize"       => problem.normalize,
                    "gauge_invariant" => problem.gauge_invariant,
                ),
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
            ),
        )

        attach!(model, sol)
    end

    return model
end
