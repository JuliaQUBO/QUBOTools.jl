function Base.convert(M::Type{<:Qubist}, model::BQPJSON{BoolDomain})
    convert(M, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:Qubist}, model::BQPJSON{SpinDomain})
    sites = maximum(model.data["variable_ids"]; init = 0) + min(1, length(model.data["variable_ids"]))
    lines = length(model.data["linear_terms"]) + length(model.data["quadratic_terms"])

    linear_terms = Dict{Int, Float64}(
        lt["id"] => lt["coeff"]
        for lt in model.data["linear_terms"]
    )    
    quadratic_terms = Dict{Tuple{Int, Int}, Float64}(
        (qt["id_head"], qt["id_tail"]) => qt["coeff"]
        for qt in model.data["quadratic_terms"]
    )

    Qubist{SpinDomain}(
        sites,
        lines,
        linear_terms,
        quadratic_terms,
    )
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::Qubist)
    data = deepcopy(DEFAULT_BQPJSON_DICT)
end