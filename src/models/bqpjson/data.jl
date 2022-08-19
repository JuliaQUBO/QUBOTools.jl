QUBOTools.backend(model::BQPJSON) = model.backend
QUBOTools.model_name(::BQPJSON) = "BQPJSON"

function QUBOTools.version(model::BQPJSON)
    version = QUBOTools.version(QUBOTools.backend(model))

    if !isnothing(version)
        return version
    else
        return BQPJSON_VERSION_LATEST
    end
end
