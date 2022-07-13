function BQPIO.backend(model::StandardBQPModel)
    model
end

function BQPIO.linear_terms(model::StandardBQPModel)
    model.linear_terms
end

function BQPIO.quadratic_terms(model::StandardBQPModel)
    model.quadratic_terms
end

function BQPIO.variable_map(model::StandardBQPModel)
    model.variable_map
end

function BQPIO.variable_map(model::StandardBQPModel{S, <:Any, <:Any, <:Any}, v::S) where S
    model.variable_map[v]
end

function BQPIO.variable_inv(model::StandardBQPModel)
    model.variable_inv
end

function BQPIO.variable_inv(model::StandardBQPModel, i::Integer)
    model.variable_inv[i]
end

function BQPIO.offset(model::StandardBQPModel)
    model.offset
end

function BQPIO.scale(model::StandardBQPModel)
    model.scale
end

function BQPIO.id(model::StandardBQPModel)
    model.id
end

function BQPIO.version(model::StandardBQPModel)
    model.version
end

function BQPIO.description(model::StandardBQPModel)
    model.description
end

function BQPIO.metadata(model::StandardBQPModel)
    model.metadata
end

function BQPIO.sampleset(model::StandardBQPModel)
    model.sampleset
end