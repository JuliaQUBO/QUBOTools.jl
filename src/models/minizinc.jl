const MINIZINC_VAR_SYMBOL = "x"

const MINIZINC_RE_COMMENT   = r"^%(\s*.*)?$"
const MINIZINC_RE_METADATA  = r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.+)$"
const MINIZINC_RE_DOMAIN    = r"^set of int\s*:\s*Domain\s*=\s*\{\s*([+-]?[0-9]+)\s*,\s*([+-]?[0-9]+)\s*\}\s*;$"
const MINIZINC_RE_FACTOR    = r"^float\s*:\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([+-]?([0-9]*[.])?[0-9]+)\s*;$"
const MINIZINC_RE_VARIABLE  = r"^var\s+Domain\s*:\s*" * MINIZINC_VAR_SYMBOL * r"([0-9]+)\s*;$"
const MINIZINC_RE_OBJECTIVE = r"^var\s+float\s*:\s*objective\s*=\s*(.+);$"

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

    function MiniZinc{D}(
        id::Integer,
        scale::Float64,
        offset::Float64,
        variable_ids::Set{Int},
        linear_terms::Dict{Int, Float64},
        quadratic_terms::Dict{Tuple{Int, Int}, Float64},
        metadata::Dict{String, Any},
        description::Union{String, Nothing},
    ) where D <: VariableDomain
        model = new{D}(
            id,
            scale,
            offset,
            variable_ids,
            linear_terms,
            quadratic_terms,
            metadata,
            description,
        )

        if isvalid(model)
            model
        else
            error("Invalid Model")
        end
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
    D               = nothing
    id              = 0
    scale           = 1.0
    offset          = 0.0
    variable_ids    = Set{Int}()
    linear_terms    = Dict{Int, Float64}()
    quadratic_terms = Dict{Tuple{Int, Int}, Float64}()
    metadata        = Dict{String, Any}()
    description     = nothing

    for line in strip.(readlines(io))
        if isempty(line)
            continue # ~ skip
        end

        # ~*~ Comments & Metadata ~*~ #
        m = match(MINIZINC_RE_COMMENT, line)
        if !isnothing(m)
            if isnothing(m[1]) 
                continue # ~ comment
            end

            m = match(MINIZINC_RE_METADATA, strip(m[1]))

            if !isnothing(m)
                key = string(m[1])
                val = string(m[2])

                if key == "id"
                    id = tryparse(Int, val)
                elseif key == "description"
                    description = val
                else
                    metadata[key] = JSON.parse(val)
                end
            end

            continue # ~ comment
        end

        # ~*~ Domain Definition ~*~
        m = match(MINIZINC_RE_DOMAIN, line)
        if !isnothing(m)
            a = tryparse(Int, m[1])
            b = tryparse(Int, m[2])

            Ω = if isnothing(a) || isnothing(b)
                error("Error while parsing variable domain")
            else
                Set{Int}([a, b])
            end
            
            D = if Ω == Set{Int}([-1, 1])
                SpinDomain
            elseif Ω == Set{Int}([ 0, 1])
                BoolDomain
            else
                error("Invalid variable set '$(Ω)'")
            end

            continue
        end

        # ~*~ Scale & Offset ~*~ #
        m = match(MINIZINC_RE_FACTOR, line)
        if !isnothing(m)
            var = string(m[1])
            val = string(m[2])

            if var == "scale"
                scale = tryparse(Float64, val)
            elseif var == "offset"
                scale = tryparse(Float64, val)
            end # ignore other constant definitions
            
            continue
        end

        # ~*~ Variables ~*~
        m = match(MINIZINC_RE_VARIABLE, line)
        if !isnothing(m)
            var_id = tryparse(Int, m[1])

            if isnothing(var_id)
                error("Error while parsing variable id")
            end

            push!(variable_ids, var_id)

            continue
        end

        # ~*~ Objective Function ~*~
        m = match(MINIZINC_RE_OBJECTIVE, line)
        if !isnothing(m)
            objective_expr = string(m[1])

            if objective_expr == "0"
                continue # empty objective, empty terms
            end

            objective_terms = strip.(split(objective_expr, "+"))

            for term in objective_terms
                @show term
            end
        end

        # it must be something else... let it go...
    end

    model = MiniZinc{D}(
        id,
        scale,
        offset,
        variable_ids,
        linear_terms,
        quadratic_terms,
        metadata,
        description,
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

    println(io, "output [show(scale*(objective + offset)), \" - \", show(objective), \" - \", show([$(var_list)])];")
end

function Base.convert(
        ::Type{<:MiniZinc{B}},
        model::MiniZinc{A}
    ) where {A <: VariableDomain, B <: VariableDomain}
    if A === B
        return model
    end
    
    id           = model.id
    scale        = model.scale
    variable_ids = copy(model.variable_ids)
    metadata     = deepcopy(model.metadata)
    description  = model.description
    offset, linear_terms, quadratic_terms = swapdomain(
        A,
        model.offset,
        model.linear_terms,
        model.quadratic_terms,
    )
    
    MiniZinc{B}(
        id,
        scale,
        offset,
        variable_ids,
        linear_terms,
        quadratic_terms,
        metadata,
        description,
    )
end