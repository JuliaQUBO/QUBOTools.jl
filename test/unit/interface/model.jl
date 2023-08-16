struct ModelWrapper
    model::QUBOTools.Model{Int,Float64,Int}

    ModelWrapper() = new(QUBOTools.Model{Int,Float64,Int}())
end

QUBOTools.backend(model::ModelWrapper) = model.model

function test_model_interface()

    return nothing
end
