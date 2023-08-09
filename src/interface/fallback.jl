""" /src/interface/fallback.jl @ QUBOTools.jl

This file contains fallback implementations by calling the model's backend.

This allows for external models to define a QUBOTools-based backend and profit from these queries.
"""

backend(::M) where {M} = error("""
                               '$M' has an incomplete inferface for 'QUBOTools'.
                               It should either implement 'backend(::$M)' or the complete 'AbstractModel' API.
                               Run `julia> ?QUBOTools.AbstractModel` for more information.
                               """)

# Data access
name(model)                  = name(backend(model))
domain(model)                = domain(backend(model))
scale(model)                 = scale(backend(model))
offset(model)                = offset(backend(model))
sense(model)                 = sense(backend(model))
id(model)                    = id(backend(model))
version(model)               = version(backend(model))
description(model)           = description(backend(model))
metadata(model)              = metadata(backend(model))
linear_terms(model)          = linear_terms(backend(model))
explicit_linear_terms(model) = explicit_linear_terms(backend(model))
quadratic_terms(model)       = quadratic_terms(backend(model))
indices(model)               = indices(backend(model))
variables(model)             = variables(backend(model))
variable_set(model)          = variable_set(backend(model))
variable_map(model)          = variable_map(backend(model))
variable_map(model, v)       = variable_map(backend(model), v)
variable_inv(model)          = variable_inv(backend(model))
variable_inv(model, i)       = variable_inv(backend(model), i)

# Model's Normal Forms
qubo(model)        = qubo(backend(model))
qubo(model, type)  = qubo(backend(model), type)
ising(model)       = ising(backend(model))
ising(model, type) = ising(backend(model), type)

# Solution queries
state(model, i)  = state(backend(model), i)
value(model, i)  = value(backend(model), i)
reads(model)     = reads(backend(model))
reads(model, i)  = reads(backend(model), i)
sample(model, i) = sample(backend(model), i)
solution(model)  = solution(backend(model))

# Data queries
dimension(model)      = dimension(backend(model))
linear_size(model)    = linear_size(backend(model))
quadratic_size(model) = quadratic_size(backend(model))
adjacency(model)      = adjacency(backend(model))
adjacency(model, k)   = adjacency(backend(model), k)

# File I/O
write_model(src, model)      = write_model(src, backend(model))
write_model(src, model, fmt) = write_model(src, backend(model), fmt)
