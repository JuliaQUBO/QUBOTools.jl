scale(model::Model)  = model.scale
offset(model::Model) = model.offset
sense(model::Model)  = model.sense
domain(model::Model) = model.domain

linear_terms(model::Model)    = model.linear_terms
quadratic_terms(model::Model) = model.quadratic_terms
variable_map(model::Model)    = model.variable_map
variable_inv(model::Model)    = model.variable_inv

id(model::Model)          = model.id
description(model::Model) = model.description
metadata(model::Model)    = model.metadata
warm_start(model::Model)  = model.warm_start
sampleset(model::Model)   = model.sampleset