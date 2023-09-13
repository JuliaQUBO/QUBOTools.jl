@doc raw"""
    Frame(sense::Sense, domain::Domain)
"""
struct Frame
    sense::Sense
    domain::Domain

    function Frame(sense, domain)
        return new(QUBOTools.sense(sense), QUBOTools.domain(domain))
    end
end

@doc raw"""
    frame(model)
"""
function frame end

const Route{X} = Pair{X,X}

@doc raw"""


Recasting the sense of a model preserves its meaning:

```math
\begin{array}{ll}
    \min_{s} \alpha [f(s) + \beta] &\equiv \max_{s} -\alpha [f(s) + \beta] \\
                                   &\equiv \max_{s} \alpha [-f(s) - \beta] \\
\end{array}
```

The linear terms, quadratic terms and constant offset of a model will have its signs reversed.

!!! warn
    Casting to the same (sense, domain) frame is a no-op.
    That means that no copying will take place automatically, thus `copy` should be called explicitly when necessary.
"""
function cast end
