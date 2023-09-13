# This file contains fallback implementations by calling the model's backend.
# This allows for external models to define a QUBOTools-based backend and profit
# from these queries.

function backend(::M) where {M}
    error("""
          '$M' has an incomplete inferface for 'QUBOTools'.
          It should either implement 'backend(::$M)' or the complete 'AbstractModel' API.
          Run `julia> ?QUBOTools.AbstractModel` for more information.
          """)

    return nothing
end

# Data access
linear_form(src)     = linear_form(backend(src))
quadratic_form(src)  = quadratic_form(backend(src))
linear_terms(src)    = linear_terms(backend(src))
quadratic_terms(src) = quadratic_terms(backend(src))
scale(src)           = scale(backend(src))
offset(src)          = offset(backend(src))
frame(src)           = frame(backend(src))
id(src)              = id(backend(src))
description(src)     = description(backend(src))
metadata(src)        = metadata(backend(src))
index(src, v)        = index(backend(src), v)
indices(src)         = indices(backend(src))
variable(src, i)     = variable(backend(src), i)
variables(src)       = variables(backend(src))

# Model's Normal Forms
form(src, args...; kws...)  = form(backend(src), args...; kws...)
qubo(src, args...; kws...)  = qubo(backend(src), args...; kws...)
ising(src, args...; kws...) = ising(backend(src), args...; kws...)

# Solution queries
state(src, i)  = state(backend(src), i)
value(src, i)  = value(backend(src), i)
reads(src)     = reads(backend(src))
reads(src, i)  = reads(backend(src), i)
sample(src, i) = sample(backend(src), i)
solution(src)  = solution(backend(src))

# Data queries
dimension(src)      = dimension(backend(src))
linear_size(src)    = linear_size(backend(src))
quadratic_size(src) = quadratic_size(backend(src))
topology(src)       = topology(backend(src))

# File I/O
write_model(dst, src)      = write_model(dst, backend(src))
write_model(dst, src, fmt) = write_model(dst, backend(src), fmt)
