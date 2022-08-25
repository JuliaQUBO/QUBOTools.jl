QUBOTools.backend(model::StandardQUBOModel) = model

Base.isvalid(::StandardQUBOModel) = true

function QUBOTools.offset(model::StandardQUBOModel{<:Any, <:Any, T, <:Any}) where {T}
    if isnothing(model.offset)
        return zero(T)
    else
        return model.offset
    end
end

function QUBOTools.scale(model::StandardQUBOModel{<:Any, <:Any, T, <:Any}) where {T}
    if isnothing(model.scale)
        return one(T)
    else
        return model.scale
    end
end

QUBOTools.id(model::StandardQUBOModel) = model.id
QUBOTools.version(model::StandardQUBOModel) = model.version
QUBOTools.description(model::StandardQUBOModel) = model.description
QUBOTools.metadata(model::StandardQUBOModel) = model.metadata
QUBOTools.sampleset(model::StandardQUBOModel) = model.sampleset

QUBOTools.linear_terms(model::StandardQUBOModel) = model.linear_terms
QUBOTools.quadratic_terms(model::StandardQUBOModel) = model.quadratic_terms

QUBOTools.variable_map(model::StandardQUBOModel) = model.variable_map
QUBOTools.variable_map(model::StandardQUBOModel{V,<:Any,<:Any,<:Any}, v::V) where {V} = model.variable_map[v]

QUBOTools.variable_inv(model::StandardQUBOModel) = model.variable_inv
QUBOTools.variable_inv(model::StandardQUBOModel, i::Integer) = model.variable_inv[i]

function QUBOTools.energy(state::Vector{U}, model::StandardQUBOModel{<:Any,U,T,<:Any}) where {U,T}
    s = zero(T)

    for (i, l) in model.linear_terms
        s += state[i] * l
    end

    for ((i, j), q) in model.quadratic_terms
        s += state[i] * state[j] * q
    end

    return s
end
