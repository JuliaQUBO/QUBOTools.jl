@doc raw"""
    density(model)::Float64

Computes the density ``\rho`` of non-zero terms in a model, according to the expression[^qplib]
```math
\rho = \frac{n_{\ell} + 2 n_{q}}{n^{2}}
```
where ``n_{\ell}`` is the number of non-zero linear terms, ``n_{q}` the number of quadratic ones and ``n`` the number of variables.

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
    time_to_target(sol::AbstractSolution{T}, λ::T, s::Float64=0.99) where {T}

Computes the _time-to-target_ (TTT) given the solution and the target threshold ``\lambda``.
The success factor ``s`` defaults to ``0.99``.

    time_to_target(t::Float64, p::Float64, s::Float64=0.99)

Computes the _time-to-target_ (TTT) given the effective time ``t`` spent running the algorithm
and the success probability ``p``.
The success factor ``s`` defaults to ``0.99``.

```math
\text{ttt}(t, p; s) = t \frac{\log(1 - s)}{\log(1 - p)}
```
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
    success_rate(sol::AbstractSolution{T}, λ::T) where {T}

Returns the success rate according to the given solution and the target objective value ``\lambda``.
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
