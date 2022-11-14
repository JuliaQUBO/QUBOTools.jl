""" /src/interface/fallback.jl @ QUBOTools.jl

This file contains fallback implementations by calling the model's backend.

This allows for external models to define a QUBOTools-based backend and profit from these queries.
"""

# ~*~ Data access ~*~ #
QUBOTools.model_name(model)            = QUBOTools.model_name(backend(model))
QUBOTools.domain(model)                = QUBOTools.domain(backend(model))
QUBOTools.domain_name(model)           = QUBOTools.domain_name(backend(model))
QUBOTools.scale(model)                 = QUBOTools.scale(backend(model))
QUBOTools.offset(model)                = QUBOTools.offset(backend(model))
QUBOTools.id(model)                    = QUBOTools.id(backend(model))
QUBOTools.version(model)               = QUBOTools.version(backend(model))
QUBOTools.description(model)           = QUBOTools.description(backend(model))
QUBOTools.metadata(model)              = QUBOTools.metadata(backend(model))
QUBOTools.sampleset(model)             = QUBOTools.sampleset(backend(model))
QUBOTools.linear_terms(model)          = QUBOTools.linear_terms(backend(model))
QUBOTools.explicit_linear_terms(model) = QUBOTools.explicit_linear_terms(backend(model))
QUBOTools.quadratic_terms(model)       = QUBOTools.quadratic_terms(backend(model))
QUBOTools.indices(model)               = QUBOTools.indices(backend(model))
QUBOTools.variables(model)             = QUBOTools.variables(backend(model))
QUBOTools.variable_set(model)          = QUBOTools.variable_set(backend(model))
QUBOTools.variable_map(model, args...) = QUBOTools.variable_map(backend(model), args...)
QUBOTools.variable_inv(model, args...) = QUBOTools.variable_inv(backend(model), args...)

# ~*~ Model's Normal Forms ~*~ #
QUBOTools.qubo(model, args...)  = QUBOTools.qubo(backend(model), args...)
QUBOTools.ising(model, args...) = QUBOTools.ising(backend(model), args...)

# ~*~ Solution queries ~*~ #
QUBOTools.state(model, args...)  = QUBOTools.state(backend(model), args...)
QUBOTools.reads(model, args...)  = QUBOTools.reads(backend(model), args...)
QUBOTools.energy(model, args...) = QUBOTools.energy(backend(model), args...)

# ~*~ Data queries ~*~ #
QUBOTools.domain_size(model)        = QUBOTools.domain_size(backend(model))
QUBOTools.linear_size(model)        = QUBOTools.linear_size(backend(model))
QUBOTools.quadratic_size(model)     = QUBOTools.quadratic_size(backend(model))
QUBOTools.density(model)            = QUBOTools.density(backend(model))
QUBOTools.linear_density(model)     = QUBOTools.linear_density(backend(model))
QUBOTools.quadratic_density(model)  = QUBOTools.quadratic_density(backend(model))
QUBOTools.adjacency(model, args...) = QUBOTools.adjacency(backend(model), args...)

# ~*~ Validation ~*~ #
QUBOTools.validate(model) = QUBOTools.validate(backend(model))