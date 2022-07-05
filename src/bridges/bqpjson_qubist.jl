function Base.convert(::Type{<:Qubist}, model::BQPJSON{BoolDomain})
    convert(Qubist{SpinDomain}, convert(BQPJSON{SpinDomain}, model))
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

function Base.convert(::Type{<:BQPJSON{BoolDomain}}, model::Qubist)
    convert(BQPJSON{BoolDomain}, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::Qubist)
    data = deepcopy(BQPJSON_DEFAULT_SPIN)

    variable_ids = Set{Int}()

    for (i, h) in model.linear_terms
        push!(variable_ids, i)
        push!(
            data["linear_terms"],
            Dict{String, Any}(
                "id"    => i,
                "coeff" => h,
            )
        )
    end

    for ((i, j), J) in model.quadratic_terms
        push!(variable_ids, i, j)
        push!(
            data["quadratic_terms"],
            Dict{String, Any}(
                "id_head" => i,
                "id_tail" => j,
                "coeff"   => J,
            )
        )
    end
    
    append!(data["variable_ids"], sort(collect(variable_ids)))

    BQPJSON{SpinDomain}(data)
end