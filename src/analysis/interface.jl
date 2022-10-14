@doc raw"""
    tts(sampleset::SampleSet{T,<:Any}, e::T; s::Float64=0.99) where {T}

Computes the _time to solution_ (TTS) from the optimal objective value and a sample set.
The success factor ``s`` defaults to ``0.99``.

    tts(t::Float64, p::Float64, s::Float64=0.99)

Computes the _time to solution_ (TTS) given the effective time ``t`` spent running the algorithm and the success probability ``p``.
The success factor ``s`` defaults to ``0.99``.

```math
\text{tts}(s; p) = \tau \frac{\log(1 - s)}{\log(1 - p)}
```
""" function tts end

@doc raw"""
    success_rate(sampleset::SampleSet{<:Any, T}, e::T) where {T}

Returns the success rate according to the given sample set and the optimal objective value.
""" function success_rate end

@doc raw"""
    total_time(sampleset::SampleSet)

Retrieves the total time spent during the whole solution gathering process, as experienced by the user.
""" function total_time end

@doc raw"""
    effective_time(sampleset::SampleSet)

Retrieves the time spent by the algorithm in the strict sense, that is, excluding time spent with data access, precompilation and other activities.
That said, it is assumed that `effective_time(sampleset) <= total_time(sampleset)`.
""" function effective_time end