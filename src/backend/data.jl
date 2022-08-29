QUBOTools.backend(model::StandardQUBOModel) = model

Base.isvalid(::StandardQUBOModel) = true

QUBOTools.sense(model::StandardQUBOModel) = model.sense

function QUBOTools.swap_sense(_model::StandardQUBOModel)
    model = copy(_model)

    source = QUBOTools.sense(model)
    target = if source === :min
        :max
    elseif source === :max
        :min
    else
        error("Invalid sense '$source'")
    end

    model.sense = target
    model.scale = -model.scale
    
    if !isnothing(model.sampleset)
        model.sampleset = QUBOTools.swap_sense(source, target, model.sampleset)
    end

    return model
end

function QUBOTools.scale(model::StandardQUBOModel{<:Any, <:Any, T, <:Any}) where {T}
    if isnothing(model.scale)
        return one(T)
    else
        return model.scale
    end
end

function QUBOTools.offset(model::StandardQUBOModel{<:Any, <:Any, T, <:Any}) where {T}
    if isnothing(model.offset)
        return zero(T)
    else
        return model.offset
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
QUBOTools.variable_inv(model::StandardQUBOModel) = model.variable_inv
