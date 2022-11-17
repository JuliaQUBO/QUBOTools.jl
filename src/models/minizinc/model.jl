const MINIZINC_BACKEND_TYPE{D} = Standard{D}

const MINIZINC_VAR_SYMBOL   = "x"
const MINIZINC_RE_COMMENT   = r"^%(\s*.*)?$"
const MINIZINC_RE_METADATA  = r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.+)$"
const MINIZINC_RE_DOMAIN    = r"^set of int\s*:\s*Domain\s*=\s*\{\s*([+-]?[0-9]+)\s*,\s*([+-]?[0-9]+)\s*\}\s*;$"
const MINIZINC_RE_FACTOR    = r"^float\s*:\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([+-]?([0-9]*[.])?[0-9]+)\s*;$"
const MINIZINC_RE_VARIABLE  = r"^var\s+Domain\s*:\s*" * MINIZINC_VAR_SYMBOL * r"([0-9]+)\s*;$"
const MINIZINC_RE_OBJECTIVE = r"^var\s+float\s*:\s*objective\s*=\s*(.+);$"

MINIZINC_DEFAULT_OFFSET(::Nothing)       = 0.0
MINIZINC_DEFAULT_OFFSET(offset::Float64) = offset

MINIZINC_DEFAULT_SCALE(::Nothing)      = 1.0
MINIZINC_DEFAULT_SCALE(scale::Float64) = scale

@doc raw"""
""" mutable struct MiniZinc{D<:VariableDomain} <: AbstractQUBOModel{D}
    backend::MINIZINC_BACKEND_TYPE{D}

    function MiniZinc{D}(backend::MINIZINC_BACKEND_TYPE{D}) where {D<:VariableDomain}
        new{D}(backend)
    end
end

function MiniZinc{D}(
    linear_terms::Dict{Int,Float64},
    quadratic_terms::Dict{Tuple{Int,Int},Float64},
    offset::Union{Float64,Nothing},
    scale::Union{Float64,Nothing},
    id::Union{Integer,Nothing},
    description::Union{String,Nothing},
    metadata::Union{Dict{String,Any},Nothing},
) where {D<:VariableDomain}
    backend = MINIZINC_BACKEND_TYPE{D}(
        linear_terms,
        quadratic_terms;
        offset      = offset,
        scale       = scale,
        id          = id,
        description = description,
        metadata    = metadata,
    )

    MiniZinc{D}(backend)
end

backend(model::MiniZinc) = model.backend
model_name(::MiniZinc)   = "MiniZinc"

function Base.read(io::IO, ::Type{MiniZinc{D}}) where {D}
    domain          = nothing
    id              = nothing
    scale           = nothing
    offset          = nothing
    variables       = Set{Int}()
    linear_terms    = Dict{Int,Float64}()
    quadratic_terms = Dict{Tuple{Int,Int},Float64}()
    metadata        = nothing
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

            domain = if Ω == Set{Int}([-1, 1])
                SpinDomain
            elseif Ω == Set{Int}([0, 1])
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
                offset = tryparse(Float64, val)
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

            push!(variables, var_id)

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

        # Let it go...
    end

    if isnothing(domain)
        error("Undefined variable domain")
    elseif domain != D
        error("Variable domain mismatch")
    end

    return MiniZinc{D}(
        linear_terms,
        quadratic_terms,
        offset,
        scale,
        id,
        description,
        metadata,
    )
end

function Base.write(io::IO, model::MiniZinc{D}) where {D<:VariableDomain}
    backend = model.backend
    println(io, "% ~*~ Generated by QUBOTools.jl ~*~")
    if !isnothing(backend.id)
        println(io, "% id : $(backend.id)")
        println(io, "%")
    end
    if !isnothing(backend.description)
        println(io, "% description : $(backend.description)")
        println(io, "%")
    end
    if !isnothing(backend.metadata)
        for (k, v) in backend.metadata
            print(io, "% $(k) : ")
            JSON.print(io, v)
            println(io)
        end
    end
    println(io, "%")
    if D <: BoolDomain
        println(io, "set of int: Domain = {0,1};")
    elseif D <: SpinDomain
        println(io, "set of int: Domain = {-1,1};")
    else
        error("Error: Invalid variable domain '$D'")
    end
    if !isnothing(backend.offset)
        println(io, "float: offset = $(backend.offset);")
    end
    if !isnothing(backend.scale)
        println(io, "float: scale = $(backend.scale);")
    end
    println(io, "%")
    mzn_var = Dict{Int,String}()
    for i = 1:length(backend.variable_map)
        xi = backend.variable_inv[i]
        mzn_var[xi] = "$(MINIZINC_VAR_SYMBOL)$(xi)"
        println(io, "var Domain: $(mzn_var[xi]);")
    end
    objective_terms = String[]
    for (i, l) in backend.linear_terms
        xi = backend.variable_inv[i]
        push!(objective_terms, "$(l)*$(mzn_var[xi])")
    end
    for ((i, j), q) in backend.quadratic_terms
        xi = backend.variable_inv[i]
        xj = backend.variable_inv[j]
        push!(objective_terms, "$(q)*$(mzn_var[xi])*$(mzn_var[xj])")
    end
    println(io, "%")
    objective_expr = isempty(objective_terms) ? "0" : join(objective_terms, " + ")
    println(io, "var float: objective = $(objective_expr);")
    println(io, "%")
    println(io, "solve minimize objective;")
    println(io, "%")
    var_list = join(
        (mzn_var[backend.variable_inv[i]] for i = 1:length(backend.variable_map)),
        ", ",
    )
    show_obj = if !isnothing(backend.offset) && !isnothing(backend.scale)
        """show(scale*(objective + offset)), " - ", show(objective)"""
    elseif !isnothing(backend.offset)
        """show(objective + offset), " - ", show(objective)"""
    elseif !isnothing(backend.scale)
        """show(scale * objective), " - ", show(objective)"""
    else
        """show(objective)"""
    end
    print(io, """output [$(show_obj), " - ", show([$(var_list)])];""")
end

function bridge(::Type{<:MiniZinc{B}}, model::MiniZinc{A}) where {A,B}
    MiniZinc{B}(bridge(MINIZINC_BACKEND_TYPE{B}, backend(model)))
end

QUBOTools.infer_model_type(::Val{:mzn}) = MiniZinc