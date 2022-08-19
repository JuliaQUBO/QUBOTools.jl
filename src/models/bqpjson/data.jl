QUBOTools.backend(model::BQPJSON) = model.backend

function QUBOTools.version(model::BQPJSON)
    version = QUBOTools.version(QUBOTools.backend(model))

    if !isnothing(version)
        return version
    else
        return BQPJSON_VERSION_LATEST
    end
end
