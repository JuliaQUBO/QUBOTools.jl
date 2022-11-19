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
""" function tts end

@doc raw"""
    success_rate(ω::SampleSet{T,<:Any}, λ::T) where {T}

Returns the success rate according to the given sample set and the optimal objective value ``\lambda``.
""" function success_rate end

@doc raw"""
    total_time(ω::SampleSet)

Retrieves the total time spent during the whole solution gathering process, as experienced by the user.
""" function total_time end

@doc raw"""
    effective_time(ω::SampleSet)

Retrieves the time spent by the algorithm in the strict sense, that is, excluding time spent with data access, precompilation and other activities.
That said, it is assumed that ``t_{\text{effective}} \le t_{\text{total}}``.
""" function effective_time end