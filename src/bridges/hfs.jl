function bridge(::Type{HFS{BoolDomain}}, model::BQPJSON{BoolDomain})
    return HFS{BoolDomain}(copy(backend(model)), Chimera(model))
end