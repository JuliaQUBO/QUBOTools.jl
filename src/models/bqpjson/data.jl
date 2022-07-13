BQPIO.backend(model::BQPJSON) = model.backend
BQPIO._default_id(::BQPJSON) = 0
BQPIO._default_version(::BQPJSON) = BQPJSON_VERSION_LATEST
BQPIO._default_metadata(::BQPJSON) = Dict{String, Any}()
BQPIO._default_offset(::BQPJSON) = 0.0
BQPIO._default_scale(::BQPJSON) = 1.0
