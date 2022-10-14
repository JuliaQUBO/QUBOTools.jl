""" /src/interface/fallback.jl @ QUBOTools.jl

This file contains fallback implementations by calling the model's backend.

This allows for external models to define a QUBOTools-based backend and profit from these queries.
"""

# ~*~ Data access ~*~ #
QUBOTools.model_name(model)            = QUBOTools.model_name(QUBOTools.backend(model))
QUBOTools.domain(model)                = QUBOTools.domain(QUBOTools.backend(model))
QUBOTools.domain_name(model)           = QUBOTools.domain_name(QUBOTools.backend(model))
QUBOTools.scale(model)                 = QUBOTools.scale(QUBOTools.backend(model))
QUBOTools.offset(model)                = QUBOTools.offset(QUBOTools.backend(model))
QUBOTools.id(model)                    = QUBOTools.id(QUBOTools.backend(model))
QUBOTools.version(model)               = QUBOTools.version(QUBOTools.backend(model))
QUBOTools.description(model)           = QUBOTools.description(QUBOTools.backend(model))
QUBOTools.metadata(model)              = QUBOTools.metadata(QUBOTools.backend(model))
QUBOTools.sampleset(model)             = QUBOTools.sampleset(QUBOTools.backend(model))
QUBOTools.linear_terms(model)          = QUBOTools.linear_terms(QUBOTools.backend(model))
QUBOTools.explicit_linear_terms(model) = QUBOTools.explicit_linear_terms(QUBOTools.backend(model))
QUBOTools.quadratic_terms(model)       = QUBOTools.quadratic_terms(QUBOTools.backend(model))
QUBOTools.variables(model)             = QUBOTools.variables(QUBOTools.backend(model))
QUBOTools.variable_set(model)          = QUBOTools.variable_set(QUBOTools.backend(model))
QUBOTools.variable_map(model, args...) = QUBOTools.variable_map(QUBOTools.backend(model), args...)
QUBOTools.variable_inv(model, args...) = QUBOTools.variable_inv(QUBOTools.backend(model), args...)

# ~*~ Model's Normal Forms ~*~ #
QUBOTools.qubo(model, args...)  = QUBOTools.qubo(QUBOTools.backend(model), args...)
QUBOTools.ising(model, args...) = QUBOTools.ising(QUBOTools.backend(model), args...)

# ~*~ Solution queries ~*~ #
QUBOTools.state(model, args...)  = QUBOTools.state(QUBOTools.backend(model), args...)
QUBOTools.energy(model, args...) = QUBOTools.energy(QUBOTools.backend(model), args...)
QUBOTools.reads(model, args...)  = QUBOTools.reads(QUBOTools.backend(model), args...)

# ~*~ Data queries ~*~ #
QUBOTools.domain_size(model)        = QUBOTools.domain_size(QUBOTools.backend(model))
QUBOTools.linear_size(model)        = QUBOTools.linear_size(QUBOTools.backend(model))
QUBOTools.quadratic_size(model)     = QUBOTools.quadratic_size(QUBOTools.backend(model))
QUBOTools.density(model)            = QUBOTools.density(QUBOTools.backend(model))
QUBOTools.linear_density(model)     = QUBOTools.linear_density(QUBOTools.backend(model))
QUBOTools.quadratic_density(model)  = QUBOTools.quadratic_density(QUBOTools.backend(model))
QUBOTools.adjacency(model, args...) = QUBOTools.adjacency(QUBOTools.backend(model), args...)