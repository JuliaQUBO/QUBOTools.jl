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
scale(src)           = scale(backend(src))
offset(src)          = offset(backend(src))
frame(src)           = frame(backend(src))
id(src)              = id(backend(src))
description(src)     = description(backend(src))
metadata(src)        = metadata(backend(src))
linear_terms(src)    = linear_terms(backend(src))
quadratic_terms(src) = quadratic_terms(backend(src))
index(src, v)        = index(backend(src), v)
indices(src)         = indices(backend(src))
variable(src, i)     = variable(backend(src), i)
variables(src)       = variables(backend(src))

# Model's Normal Forms
form(src; domain = domain(src), sense = sense(src))       = form(backend(src))
form(src, type; domain = domain(src), sense = sense(src)) = form(backend(src), type)
qubo(src; sense = sense(src))                             = qubo(backend(src))
qubo(src, type; sense = sense(src))                       = qubo(backend(src), type)
ising(src; sense = sense(src))                            = ising(backend(src))
ising(src, type; sense = sense(src))                      = ising(backend(src), type)

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
topology(src, k)    = topology(backend(src), k)

# File I/O
write_model(dst, src)      = write_model(dst, backend(src))
write_model(dst, src, fmt) = write_model(dst, backend(src), fmt)
