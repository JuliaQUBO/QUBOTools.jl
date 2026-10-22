@doc raw"""
    density(model)::Float64

Computes the density ``\rho`` of non-zero terms in a model, according to the expression[^qplib]
```math
\rho = \frac{n_{\ell} + 2 n_{q}}{n^{2}}
```
where ``n_{\ell}`` is the number of non-zero linear terms, ``n_{q}`` the number of quadratic ones and ``n`` the number of variables.

If the model is empty, returns `NaN`.

[^qplib]:
    **QPLIB: A Library of Quadratic Programming Instances** [{docs}](https://qplib.zib.de/doc.html#objquaddensity)
"""
function density end

@doc raw"""
    linear_density(model)::Float64

Computes the linear density ``\rho_{\ell}``, given by
```math
\rho_{\ell} = \frac{n_{\ell}}{n}
```
where ``n_{\ell}`` is the number of non-zero linear terms and ``n`` the number of variables.
"""
function linear_density end

@doc raw"""
    quadratic_density(model)::Float64

Computes the quadratic density ``\rho_{q}``, given by
```math
\rho_{q} = \frac{2 n_{q}}{n (n - 1)}
```
where ``n_{q}`` is the number of non-zero quadratic terms and ``n`` the number of variables.
"""
function quadratic_density end

@doc raw"""
    TimeToTargetEstimate

Structured time-to-target (TTT) estimate preserving trial units, cost boundary,
empirical vs. known probability provenance, and both operational (integer-restart)
and continuous-relaxation repeat counts.

Fields:

- `ttt::Float64`: time-to-target under the selected `repetition_mode`;
- `operational_ttt::Float64`: executable restart cost `trial_time * operational_repetitions`, charging at least one trial when `p > 0`;
- `continuous_ttt::Float64`: continuous relaxation `trial_time * continuous_repetitions`;
- `repetitions::Float64`: repetition count under the selected `repetition_mode`;
- `operational_repetitions::Float64`: integer repeat count $\max(1, \lceil \log(1 - s) / \log(1 - p) \rceil)$ (`1.0` at $p = 1$, `Inf` at $p = 0$);
- `continuous_repetitions::Float64`: continuous relaxation $\log(1 - s) / \log(1 - p)$ (`0.0` at $p = 1$, `Inf` at $p = 0$);
- `trial_time::Float64`: duration per trial in seconds;
- `batch_time::Float64`: total duration of the evaluated batch or campaign in seconds;
- `target_probability::Float64`: target success probability $s \in (0, 1)$;
- `success_probability::Float64`: per-trial success probability $p \in [0, 1]$;
- `trials::Union{Int,Nothing}`: finite trial count when `probability_source === :empirical`, or `nothing` when `:known`;
- `successes::Union{Int,Nothing}`: observed successful trials when `probability_source === :empirical`, or `nothing` when `:known`;
- `trial_unit::Symbol`: `:read`, `:run`, or `:trial`;
- `cost_boundary::Symbol`: `:effective`, `:total`, `:complete`, or `:unspecified`;
- `probability_source::Symbol`: `:known` or `:empirical`;
- `repetition_mode::Symbol`: `:integer`, `:continuous_floor_one`, or `:continuous`;
- `status::Symbol`: `:known_interior_probability`, `:known_unit_probability`, `:known_zero_probability`, `:empirical_interior_probability`, `:empirical_all_succeeded`, or `:empirical_zero_successes`.
"""
struct TimeToTargetEstimate
    ttt::Float64
    operational_ttt::Float64
    continuous_ttt::Float64
    repetitions::Float64
    operational_repetitions::Float64
    continuous_repetitions::Float64
    trial_time::Float64
    batch_time::Float64
    target_probability::Float64
    success_probability::Float64
    trials::Union{Int,Nothing}
    successes::Union{Int,Nothing}
    trial_unit::Symbol
    cost_boundary::Symbol
    probability_source::Symbol
    repetition_mode::Symbol
    status::Symbol
end

@doc raw"""
    time_to_target_estimate(sol::AbstractSolution, λ::Real, s::Real = 0.99;
        trial_unit = nothing, cost_boundary = :effective, trial_time = nothing,
        batch_time = nothing, repetition_mode = :integer)
    time_to_target_estimate(solutions::AbstractVector{<:AbstractSolution}, λ::Real, s::Real = 0.99;
        trial_unit = :run, cost_boundary = :effective, trial_time = nothing,
        batch_time = nothing, repetition_mode = :integer)
    time_to_target_estimate(trial_time::Real, p::Real, s::Real = 0.99;
        cost_boundary = :unspecified, repetition_mode = :integer, trial_unit = :trial)
    time_to_target_estimate(trial_time::Real; successes::Integer, trials::Integer,
        s::Real = 0.99, cost_boundary = :unspecified, repetition_mode = :integer,
        trial_unit = :trial, batch_time = nothing)

Compute a structured [`TimeToTargetEstimate`](@ref) with matching probability and
time units and explicit endpoint semantics:

- `trial_unit = :read` treats each read in `sol` as an independent trial (`trials = reads(sol)` and `trial_time = batch_time / trials` unless `trial_time` is supplied). Solutions marked in metadata as correlated, selected, repaired, or best-only are rejected for `:read`.
- `trial_unit = :run` treats a single `SampleSet` as one solver run (`trials = 1`, `trial_time = batch_time`), or a vector of `SampleSet`s as `length(solutions)` independent runs.
- `cost_boundary` selects `:effective` (strictly `metadata["time"]["effective"]`), `:total` (strictly `metadata["time"]["total"]`), or `:complete` (caller-supplied `trial_time`/`batch_time` or `metadata["time"]["complete"]`) without silently substituting one boundary for another.
"""
function time_to_target_estimate end

@doc raw"""
    time_to_target(sol::AbstractSolution, λ::Real, s::Real = 0.99;
        trial_unit = nothing, cost_boundary = :effective, trial_time = nothing,
        batch_time = nothing, repetition_mode = :continuous_floor_one)
    time_to_target(solutions::AbstractVector{<:AbstractSolution}, λ::Real, s::Real = 0.99;
        trial_unit = :run, cost_boundary = :effective, trial_time = nothing,
        batch_time = nothing, repetition_mode = :continuous_floor_one)
    time_to_target(t::Real, p::Real, s::Real = 0.99;
        repetition_mode = :continuous_floor_one)

Compute the scalar time-to-target (TTT) for threshold ``\lambda`` and target
success probability ``s \in (0, 1)`` (default `0.99`).

When called with a `SampleSet`, pass `trial_unit = :read` (independent reads) or
`trial_unit = :run` (single solver run) so the trial duration and success
probability share the same unit. Calling `time_to_target(sol, λ, s)` without
`trial_unit` is deprecated because it mixes whole-batch timing with per-read
success probability.

For a known per-trial success probability ``p`` and positive trial cost ``t``:
- ``p = 0`` returns `Inf`;
- ``p = 1`` charges one trial (`t`) under `:integer` and `:continuous_floor_one`
  (or `0.0` only when `repetition_mode = :continuous` is explicitly requested);
- ``0 < p < 1`` uses ``\max(1, \log(1 - s) / \log(1 - p))`` for
  `:continuous_floor_one` and ``\max(1, \lceil \log(1 - s) / \log(1 - p) \rceil)``
  for `:integer`.
"""
function time_to_target end

@doc raw"""
    ttt

Alias for [`time_to_target`](@ref).
"""
const ttt = time_to_target

# @doc raw"""
#     opt_ttt(
#         r::Function,
#         solutions::AbstractVector{S},
#         λ::T,
#         s::Float64 = 0.99,
#         q::Float64 = 0.5,
#     ) where {T,U,S<:AbstractSolution{T,U}}

#     opt_ttt(
#         solutions::AbstractVector{S},
#         λ::T,
#         s::Float64 = 0.99,
#         q::Float64 = 0.5,
#         r::Float64 = 1.0,
#     ) where {T,U,S<:AbstractSolution{T,U}}

# Computes the _optimal time-to-target_ (optTTT) from a list of solutions given a threshold ``\lambda``,
# a probability ``s``, a quantile ``q`` and a parallelization factor ``r(n)`` where ``n`` is the number of spins.

# ```math
# \textrm{optTTT}(\mathbf{t}; s, q) = \min_{t} \left\langle t \frac{\log(1 - s)}{\log(1 - p(t))} \right\rangle_{q} \frac{1}{r(n)}
# ```

# The success factor ``s`` defaults to ``0.99`` and the quantile ``q`` defaults to ``0.5`` (the median).
# No parallelism is assumed, i.e. ``k = 1`` by default.

# - ``t`` is the time the algorithm spent running.
# - ``r(n)`` is the parallelization factor, i.e., how many replicas of the same instance can be run in parallel.
# - ``p_{i}(t)`` is the probability that the optimal solution is found for the ``i``-th instance.
# - ``p_{i}'(t) = 1 - (1 - p_{i}(t))^{r(n)}`` is the probability that at least one of the replicas will reach the target energy.
# - ``\left\langle\,\cdot\,\right\rangle_{q}`` denotes taking the ``q``-th quantile over the distribution of instances.

# Let ``R_{s}`` be the number of runs required to find the target solution at least once with probability ``s``.
# Then, ``s = 1 - (1 - p_{i}'(t))^{R_{s}}`` and ``\textrm{TTT} = t R_{s}``.

# ## References
# [^Kowalsky]:
#     **3-Regular 3-XORSAT Planted Solutions Benchmark of Classical and Quantum Heuristic Optimizers**, _Matthew Kowalsky_, _Tameem Albash_, _Itay Hen_, _Daniel A. Lidar_. [{arXiv}](https://arxiv.org/abs/2103.08464)
# """
# function opt_ttt end

@doc raw"""
    success_rate(sol::AbstractSolution{T}, λ::Real; trial_unit::Symbol = :read) where {T}
    success_rate(solutions::AbstractVector{<:AbstractSolution}, λ::Real; trial_unit::Symbol = :run)

Return the empirical success rate for target objective value ``\lambda`` under
the declared `trial_unit` (`:read` for read-multiplicity fraction within a batch,
or `:run` for run-level attainment).
"""
function success_rate end

@doc raw"""
    total_time(sol::AbstractSolution)

Retrieves the total time spent during the whole solution gathering process, as experienced by the user.
"""
function total_time end

@doc raw"""
    effective_time(sol::AbstractSolution)

Retrieves the time spent by the algorithm in the strict sense, that is, excluding time spent with data access, precompilation and other activities.
That said, it is assumed that ``t_{\text{effective}} \le t_{\text{total}}``.
"""
function effective_time end

@doc raw"""
    hamming_distance(x::Vector{U}, y::Vector{U}) where {U}
    hamming_distance(x::Sample{T,U}, y::Sample{T,U}) where {T,U}
"""
function hamming_distance end

@doc raw"""
    AbstractVisualization

Represents a conceptual visualization built from a set of data structures.
Its realization may combine multiple plot recipes as well.

# Examples

## Model Density Heatmap

```julia
julia> using Plots

julia> p = QUBOTools.ModelDensityPlot(model)

julia> plot(p)
```

## Solution Energy vs. Frequency

```julia
julia> using Plots

julia> s = QUBOTools.solution(model)

julia> p = QUBOTools.EnergyFrequencyPlot(s)

julia> plot(p)
```

or simply,

```julia
julia> using Plots

julia> p = QUBOTools.EnergyFrequencyPlot(model)

julia> plot(p)
```
"""
abstract type AbstractVisualization end
