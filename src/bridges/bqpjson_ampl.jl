function Base.convert(::Type{<:AMPL}, model::BQPJSON{SpinDomain})
    convert(AMPL{BoolDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{<:AMPL}, model::BQPJSON{BoolDomain})
    backend = copy(model.backend)

    AMPL{SpinDomain}(backend)
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::AMPL)
    convert(BQPJSON{SpinDomain}, convert(BQPJSON{BoolDomain}, model))
end

function Base.convert(::Type{<:BQPJSON{BoolDomain}}, model::AMPL)
    backend   = copy(model.backend)
    solutions = nothing

    BQPJSON{BoolDomain}(backend, solutions)
end