""" /src/interface/fallback.jl @ QUBOTools.jl

This file contains fallback implementations by calling the model's backend.

This allows for external models to define a QUBOTools-based backend and profit from these queries.
"""

# ~*~ Data access ~*~ #
model_name(model)            = model_name(backend(model))
domain(model)                = domain(backend(model))
domain_name(model)           = domain_name(backend(model))
scale(model)                 = scale(backend(model))
offset(model)                = offset(backend(model))
sense(model)                 = sense(backend(model))
id(model)                    = id(backend(model))
version(model)               = version(backend(model))
description(model)           = description(backend(model))
metadata(model)              = metadata(backend(model))
sampleset(model)             = sampleset(backend(model))
linear_terms(model)          = linear_terms(backend(model))
explicit_linear_terms(model) = explicit_linear_terms(backend(model))
quadratic_terms(model)       = quadratic_terms(backend(model))
indices(model)               = indices(backend(model))
variables(model)             = variables(backend(model))
variable_set(model)          = variable_set(backend(model))
variable_map(model, args...) = variable_map(backend(model), args...)
variable_inv(model, args...) = variable_inv(backend(model), args...)

# ~*~ Model's Normal Forms ~*~ #
qubo(model, args...)  = qubo(backend(model), args...)
ising(model, args...) = ising(backend(model), args...)

# ~*~ Solution queries ~*~ #
state(model, args...) = state(backend(model), args...)
value(model, args...) = value(backend(model), args...)
reads(model, args...) = reads(backend(model), args...)

# ~*~ Data queries ~*~ #
domain_size(model)        = domain_size(backend(model))
linear_size(model)        = linear_size(backend(model))
quadratic_size(model)     = quadratic_size(backend(model))
density(model)            = density(backend(model))
linear_density(model)     = linear_density(backend(model))
quadratic_density(model)  = quadratic_density(backend(model))
adjacency(model, args...) = adjacency(backend(model), args...)