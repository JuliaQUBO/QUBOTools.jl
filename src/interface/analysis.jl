@doc raw"""
    density(model)::Float64

Computes the density ``\rho`` of non-zero terms in a model, according to the expression
```math
\rho = \frac{n_{\ell} + 2 n_{q}}{n^{2}}
```
where ``n_{\ell}`` is the number of non-zero linear terms, ``n_{q}` the number of quadratic ones and ``n`` the number of variables.

If the model is empty, returns `NaN`.
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
    tts(ω::SampleSet{T,<:Any}, λ::T, s::Float64=0.99) where {T}

Computes the _time to solution_ (TTS) from the optimal objective value and a sample set.
The success factor ``s`` defaults to ``0.99``.

    tts(t::Float64, p::Float64, s::Float64=0.99)

Computes the _time to solution_ (TTS) given the effective time ``t`` spent running the algorithm and the success probability ``p``.
The success factor ``s`` defaults to ``0.99``.

```math
\text{tts}(t, p; s) = t \frac{\log(1 - s)}{\log(1 - p)}
```
"""
function tts end

@doc raw"""
    opt_tts(solution::AbstractVector{S}, λ::T, s::Float64 = 0.99, q::Float64 = 0.5) where {T,U,S<:AbstractSolution{T,U}}

Computes the _optimal time-to-solution_ (optTTS) from the ground-state value and a vector of solutions given a probability ``s`` and a quantile ``q``.

The success factor ``s`` defaults to ``0.99`` and the quantile ``q`` defaults to ``0.5``, i.e., the median.

```math
\textrm{optTTS}(t, p; s, q) = \left\langle t \frac{\log(1 - s)}{\log(1 - p)} \right\rangle_{q}
```
"""
function opt_tts end

@doc raw"""
    success_rate(ω::SampleSet{T,<:Any}, λ::T) where {T}

Returns the success rate according to the given sample set and the optimal objective value ``\lambda``.
"""
function success_rate end

@doc raw"""
    total_time(ω::SampleSet)

Retrieves the total time spent during the whole solution gathering process, as experienced by the user.
"""
function total_time end

@doc raw"""
    effective_time(ω::SampleSet)

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
