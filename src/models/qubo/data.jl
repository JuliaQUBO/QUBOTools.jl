QUBOTools.backend(model::QUBO) = model.backend
QUBOTools.model_name(model::AbstractQUBOModel{<:BoolDomain}) = "QUBO"