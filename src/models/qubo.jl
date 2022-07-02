# const QUBO_SCHEMA = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "qubo.schema.json")))

@doc raw"""
""" mutable struct QUBO{D <: BoolDomain} <: Model{D}
    data::Dict{String, Any}

    function QUBO{D}(data::Dict{String, Any}) where D <: BoolDomain
        new{D}(data)
    end

    function QUBO(data::Dict{String, Any})
        QUBO{BoolDomain{Int}}(data)
    end
end

function Base.write(io::IO, model::QUBO)
    println(io, "c id : $(model.data["id"])")
    if !isnothing(model.data["description"])
        println(io, "c id : $(model.data["description"])")
    end
    println(io, "c")
    println(io, "c scale : $(model.data["scale"])")
    println(io, "c offset : $(model.data["offset"])")
    for (k, v) in data["metadata"]
        print(io, "c $(k) : ")
        JSON.print(io, v)
        println(io)
    end

    max_index     = maximum(data["variable_ids"]) + (length(data["variable_ids"]) > 0 ? 1 : 0)
    num_diagonals = length(data["linear_terms"])
    num_elements  = length(data["quadratic_terms"])

    println(io, "p qubo 0 $(max_index) $(num_diagonals) $(num_elements)\n")
    println(io, "c linear terms\n")
    for (i, j, c) in data["linear_terms"]
        println(io, "$(i) $(j) $(c)")
    end
    println(io, "c quadratic terms")
    for (i, j, c) in data["quadratic_terms"]
        println(io, "$(i) $(j) $(c)")
    end
end

function Base.read(io::IO, M::Type{<:QUBO})
    data = Dict{String, Any}(
        "id" => nothing,
        "description" => nothing,
        "scale" => nothing,
        "offset" => nothing,
        "metadata" => Dict{String, Any}(),
        "linear_terms" => Dics{String, Any}[],
        "quadratic_terms" => Dics{String, Any}[],
        "max_index" => nothing,
        "num_diagonals" => nothing,
        "num_elements" => nothing,
    )

    for line in readlines(io)
        m = match(r"c (.*)", line)

        if !isnothing(m)
            s = m[1]
            m = match(r"([a-zA-Z][a-zA-Z0-9]+) : (.*)", s)
            if !isnothing(m)
                k = m[1]
                v = m[2]

                if k == "id"
                    data["id"] = tryparse(Integer, v)
                elseif k == "description"
                    data["description"] = v
                elseif k == "scale"
                    data["scale"] = tryparse(Float64, v)
                elseif k == "offset"
                    data["offset"] = tryparse(Float64, v)
                else
                    data["metadata"][k] = JSON.parse(v)
                end
            end

            continue
        end

        m = match(r"p qubo 0 ([0-9]+) ([0-9]+) ([0-9]+)", line)

        if !isnothing(m)
            max_index     = tryparse(Integer, m[1])
            num_diagonals = tryparse(Integer, m[2])
            num_elements  = tryparse(Integer, m[3])

            if isnothing(max_index) || isnothing(num_diagonals) || isnothing(num_elements)
                throw(BQPError("Error parsing '$line'"))
            end

            data["max_index"]     = max_index
            data["num_diagonals"] = num_diagonals
            data["num_elements"]  = num_elements

            continue
        end

        m = match(r"([0-9]+) ([0-9]+) ([0-9.]+)", line)

        if !isnothing(m)
            i = tryparse(Integer, m[1])
            j = tryparse(Integer, m[2])
            c = tryparse(Float64, m[3])

            if isnothing(i) || isnothing(j) || isnothing(c)
                throw(BQPError("Error parsing '$line'"))
            end

            if i == j
                push!(data["linear_terms"], Dict{String, Any}(
                    "id" => i,
                    "coeff" => c,
                ))
            else
                push!(data["quadratic_terms"], Dict{String, Any}(
                    "id_head" => i,
                    "id_tail" => j,
                    "coeff" => c,
                ))
            end
        end
    end

    data
end