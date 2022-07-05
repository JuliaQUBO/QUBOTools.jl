const MINIZINC_VAR_SYMBOL = "x"

@doc raw"""
""" struct MiniZinc{D <: VariableDomain} <: AbstractBQPModel{D}
    id::Int

    scale::Float64
    offset::Float64

    variable_ids::Set{Int}

    linear_terms::Dict{Int, Float64}
    quadratic_terms::Dict{Tuple{Int, Int}, Float64}

    metadata::Dict{String, Any}
    description::Union{String, Nothing}

    function MiniZinc{D}(data::Dict{String, Any}) where D <: VariableDomain
        new{D}(data)
    end
end

function Base.isvalid(model::MiniZinc)
    if !isfinite(model.scale) || !isfinite(model.offset)
        @error "I"
        return false
    end

    for (i, a) in model.linear_terms
        if i ∉ model.variable_ids || !isfinite(a)
            @error "II"
            return false
        end
    end

    for ((i, j), a) in model.quadratic_terms
        if i ∉ model.variable_ids || j ∉ model.variable_ids || j <= i || !isfinite(a)
            @error "III"
            return false
        end
    end

    return true
end

function Base.read(io::IO, M::Type{<:MiniZinc})
    id              = 0
    scale           = 1.0
    offset          = 0.0
    variable_ids    = Set{Int}()
    linear_terms    = Dict{Int, Float64}()
    quadratic_terms = Dict{Int, Float64}()
    metadata        = Dict{String, Any}()
    description     = nothing

    for line in strip.(readlines(io))
        # ~*~ Comments & Metadata ~*~ #
        m = match(r"^%(\s.*)?$", line)
        if !isnothing(m)
            if isnothing(m[1]) # comment
                continue
            end


        end



    end

    model = MiniZinc{D}(

    )

    if (model isa M)
        model
    else
        convert(M, model)
    end
end

function Base.write(io::IO, model::MiniZinc{D}) where D <: VariableDomain
    println(io, "% id : $(model.id)")

    if !isnothing(model.description)
        println(io, "% description : $(model.description)")
    end

    println(io, "%")

    for (k, v) in model.metadata
        print(io, "% $(k) : ")
        JSON.print(io, v)
        println(io)
    end

    println(io, "%")

    if D <: BoolDomain
        println(io, "set of int: Domain = {0,1};")
    elseif D <: SpinDomain
        println(io, "set of int: Domain = {-1,1};")
    else
        error("Error: Invalid variable domain '$D'")
    end

    println(io, "float: scale = $(model.scale);")
    println(io, "float: offset = $(model.offset);")
    println(io, "%")

    mzn_var = Dict{Int, String}()
    for i in model.variable_ids
        mzn_var[i] = "$(MINIZINC_VAR_SYMBOL)$(i)"
        println(io, "var Domain: $(mzn_var[i]);")
    end

    objective_terms = String[]
    for (i, a) in model.linear_terms
        push!(objective_terms, "$(a)*$(mzn_var[i])")
    end

    for ((i, j), a) in model.quadratic_terms
        push!(objective_terms, "$(a)*$(mzn_var[i])*$(mzn_var[j])")
    end

    println(io, "%")
    objective_expr = isempty(objective_terms) ? "0" : join(objective_terms, " + ")
    println(io, "var float: objective = $(objective_expr);")

    println(io, "%")
    println(io, "solve minimize objective;")

    println(io, "%")
    var_list = join((mzn_var[i] for i in sort(collect(model.variable_ids))), ", ")

    println(io, "output [show(scale*(objective + offset)), \" - \", show(objective), \" - \", show([$(var_list))])];")
end