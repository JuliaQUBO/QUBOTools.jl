form(model::Model)      = model.form
dimension(model::Model) = dimension(form(model))
scale(model::Model)     = scale(form(model))
offset(model::Model)    = offset(form(model))
sense(model::Model)     = model.sense
domain(model::Model)    = model.domain

linear_terms(model::Model)    = linear_terms(form(model))
quadratic_terms(model::Model) = quadratic_terms(form(model))
variable_map(model::Model)    = model.variable_map
variable_inv(model::Model)    = model.variable_inv

id(model::Model)          = get(metadata(model), "id", nothing)
description(model::Model) = get(metatada(model), "description", nothing)
metadata(model::Model)    = model.metadata
warm_start(model::Model)  = model.warm_start
solution(model::Model)    = model.solution