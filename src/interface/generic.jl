const Route{X} = Pair{X,X}

@doc raw"""
    cast(
        sense_route::Pair{A,B},
        domain_route::Pair{X,Y},
        data,
    ) where {A<:Sense,B<:Sense,X<:Domain,Y<:Domain}

    cast(::S, ::S, model::AbstractModel) where {S<:Sense}
    cast(::A, ::B, model::AbstractModel) where {A<:Sense,B<:Sense}

Recasting the sense of a model preserves its meaning:

```math
\begin{array}{ll}
    \min_{s} \alpha [f(s) + \beta] &\equiv \max_{s} -\alpha [f(s) + \beta] \\
                                   &\equiv \max_{s} \alpha [-f(s) - \beta] \\
\end{array}
```

The linear terms, quadratic terms and constant offset of a model have its signs reversed.

    cast(route, s::Sample)
    cast(route, s::Sample)
    cast(route, ω::SampleSet)
    cast(route, ω::SampleSet)

    cast(route, model::AbstractModel)
    cast(route, ψ::Vector{U})
    cast(route, Ψ::Vector{Vector{U}})
    cast(route, ω::SampleSet)

Returns a new object, switching its domain from `source` to `target`.

Reverses the sign of the objective value.

!!! warn
    Casting to the same (sense, domain) frame is a no-op.
    That means that no copying will take place automatically, thus `copy` should be called explicitly when necessary.
"""
function cast end

@doc raw"""
    validate(model)::Bool
    validate(ω::AbstractSampleSet)::Bool

"""
function validate end
