""" /src/fallback/data.jl @ QUBOTools.jl

This file contains fallback implementations by calling the model's backend.

This allows for external models to define a QUBOTools-based backend and profit from these queries.
"""

QUBOTools.model_name(model) = QUBOTools.model_name(QUBOTools.backend(model))
QUBOTools.domain_name(model) = QUBOTools.domain_name(QUBOTools.backend(model))
QUBOTools.offset(model) = QUBOTools.offset(QUBOTools.backend(model))
QUBOTools.scale(model) = QUBOTools.scale(QUBOTools.backend(model))
QUBOTools.id(model) = QUBOTools.id(QUBOTools.backend(model))
QUBOTools.version(model) = QUBOTools.version(QUBOTools.backend(model))
QUBOTools.description(model) = QUBOTools.description(QUBOTools.backend(model))
QUBOTools.metadata(model) = QUBOTools.metadata(QUBOTools.backend(model))
QUBOTools.sampleset(model) = QUBOTools.sampleset(QUBOTools.backend(model))

function QUBOTools.linear_terms(model; explicit::Bool=false)
    linear_terms = QUBOTools.linear_terms(QUBOTools.backend(model))

    if explicit
        return QUBOTools._explicit_linear_terms(
            linear_terms,
            QUBOTools.variable_inv(model)
        )
    else
        return linear_terms
    end
end

function _explicit_linear_terms(
    linear_terms::Dict{Int,T},
    variable_inv::Dict{Int,<:Any},
) where {T}
    merge(
        Dict{Int,T}(i => zero(T) for i in keys(variable_inv)),
        linear_terms,
    )
end

QUBOTools.quadratic_terms(model) = QUBOTools.quadratic_terms(QUBOTools.backend(model))

function QUBOTools.variables(model)
    variable_map = QUBOTools.variable_map(QUBOTools.backend(model))

    return sort(collect(keys(variable_map)))
end

function QUBOTools.variable_set(model)
    variable_map = QUBOTools.variable_map(QUBOTools.backend(model))

    return Set(keys(variable_map))
end

QUBOTools.variable_map(model) = QUBOTools.variable_map(QUBOTools.backend(model))
QUBOTools.variable_map(model, v) = QUBOTools.variable_map(QUBOTools.backend(model), v)
QUBOTools.variable_inv(model) = QUBOTools.variable_inv(QUBOTools.backend(model))
QUBOTools.variable_inv(model, i) = QUBOTools.variable_inv(QUBOTools.backend(model), i)
QUBOTools.qubo(model) = QUBOTools.qubo(QUBOTools.backend(model))
QUBOTools.ising(model) = QUBOTools.ising(QUBOTools.backend(model))
QUBOTools.energy(model) = QUBOTools.energy(QUBOTools.backend(model))
QUBOTools.domain_size(model) = QUBOTools.domain_size(QUBOTools.backend(model))
QUBOTools.linear_size(model) = QUBOTools.linear_size(QUBOTools.backend(model))
QUBOTools.quadratic_size(model) = QUBOTools.quadratic_size(QUBOTools.backend(model))
QUBOTools.density(model) = QUBOTools.density(QUBOTools.backend(model))
QUBOTools.linear_density(model) = QUBOTools.linear_density(QUBOTools.backend(model))
QUBOTools.quadratic_density(model) = QUBOTools.quadratic_density(QUBOTools.backend(model))