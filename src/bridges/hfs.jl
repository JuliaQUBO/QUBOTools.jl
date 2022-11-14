function bridge(::Type{HFS{BoolDomain}}, model::BQPJSON{BoolDomain}; kws...)
    return HFS{BoolDomain}(copy(backend(model)), Chimera(model; kws...))
end