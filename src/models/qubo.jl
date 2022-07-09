# const QUBO_SCHEMA = JSONSchema.Schema(JSON.parsefile(joinpath(@__DIR__, "qubo.schema.json")))

@doc raw"""
""" struct QUBO{D <: BoolDomain} <: AbstractBQPModel{D}
    id::Int
    scale::Float64
    offset::Float64

    max_index::Int
    num_diagonals::Int
    num_elements::Int

    linear_terms::Dict{Int, Float64}
    quadratic_terms::Dict{Tuple{Int, Int}, Float64}

    metadata::Dict{String, Any}
    description::Union{String, Nothing}

    function QUBO{D}(
        id::Int,
        scale::Float64,
        offset::Float64,
        max_index::Int,
        num_diagonals::Int,
        num_elements::Int,
        linear_terms::Dict{Int, Float64},
        quadratic_terms::Dict{Tuple{Int, Int}, Float64},
        metadata::Dict{String, Any},
        description::Union{String, Nothing},
    ) where D <: BoolDomain
        model = new{D}(
            id,
            scale,
            offset,
            max_index,
            num_diagonals,
            num_elements,
            linear_terms,
            quadratic_terms,
            metadata,
            description,
        )
        if isvalid(model)
            model
        else
            error()
        end
    end

    function QUBO(args...)
        QUBO{BoolDomain}(args...)
    end
end

function Base.isapprox(x::QUBO, y::QUBO; kw...)
    isapprox(x.scale , y.scale ; kw...) &&
    isapprox(x.offset, y.offset; kw...) &&
    isapproxdict(x.linear_terms   , y.linear_terms   ; kw...) &&
    isapproxdict(x.quadratic_terms, y.quadratic_terms; kw...)
end

function Base.:(==)(x::QUBO, y::QUBO)
    x.id              == y.id              &&
    x.scale           == y.scale           &&
    x.offset          == y.offset          &&
    x.max_index       == y.max_index       &&
    x.num_diagonals   == y.num_diagonals   &&
    x.num_elements    == y.num_elements    &&
    x.linear_terms    == y.linear_terms    &&
    x.quadratic_terms == y.quadratic_terms &&
    x.metadata        == y.metadata        &&
    x.description     == y.description     
end

function Base.isvalid(model::QUBO)
    if isnan(model.scale) || isinf(model.scale) || model.scale < 0.0
        @error "Negative or invalid value for 'scale'"
        return false
    end

    if isnan(model.offset) || isinf(model.offset)
        @error "Invalid value for 'offset'"
        return false
    end

    if model.max_index < 0
        @error ""
        return false
    end

    if model.num_diagonals < 0
        @error ""
        return false
    end

    if model.num_elements < 0
        @error ""
        return false
    end

    for (i, q) in model.linear_terms
        if i < 0 || !isfinite(q)
            @error "Invalid linear term '$(i) => $(Q)'"
            return false
        end
    end

    for ((i, j), Q) in model.quadratic_terms
        if i >= j || i < 0 || j < 0 || !isfinite(Q)
            @error "Invalid quadratic term '($(i), $(j)) => $(Q)'"
            return false
        end
    end

    return true
end

function Base.write(io::IO, model::QUBO)
    println(io, "c id : $(model.id)")
    if !isnothing(model.description)
        println(io, "c description : $(model.description)")
        println(io, "c")
    end
    println(io, "c scale : $(model.scale)")
    println(io, "c offset : $(model.offset)")
    for (k, v) in model.metadata
        print(io, "c $(k) : ")
        JSON.print(io, v)
        println(io)
    end
    println(io, "p qubo 0 $(model.max_index) $(model.num_diagonals) $(model.num_elements)")
    println(io, "c linear terms")
    for (i, q) in model.linear_terms
        println(io, "$(i) $(i) $(q)")
    end
    println(io, "c quadratic terms")
    for ((i, j), Q) in model.quadratic_terms
        println(io, "$(i) $(j) $(Q)")
    end
end

function Base.read(io::IO, ::Type{<:QUBO})
    id     = 0
    scale  = 1.0
    offset = 0.0
    
    max_index     = nothing
    num_diagonals = nothing
    num_elements  = nothing

    linear_terms    = Dict{Int, Float64}()
    quadratic_terms = Dict{Tuple{Int, Int}, Float64}()

    metadata    = Dict{String, Any}()
    description = nothing

    for line in strip.(readlines(io))
        if isempty(line)
            continue # ~ skip
        end

        # -*- Comments & Metadata -*-
        m = match(r"^c(\s.*)?$", line) 

        if !isnothing(m)
            if isnothing(m[1])
                continue # ~ comment
            end

            # -*- Metadata -*-
            m = match(r"([a-zA-Z][a-zA-Z0-9_]+)\s*:\s*(.+)$", strip(m[1]))
            if !isnothing(m)
                key = string(m[1])
                val = string(m[2])

                if key == "id"
                    id = tryparse(Int, val)
                elseif key == "scale"
                    scale = tryparse(Float64, val)
                elseif key == "offset"
                    offset = tryparse(Float64, val)
                elseif key == "description"
                    description = val
                else
                    metadata[key] = JSON.parse(val)
                end
            end

            continue # ~ comment
        end

        # -*- Problem Header -*-
        m = match(r"^p\s+qubo\s+([+-]?[0-9]+)\s+([+-]?[0-9]+)\s+([+-]?[0-9]+)\s+([+-]?[0-9]+)$", line)

        if !isnothing(m)
            max_index     = tryparse(Int, m[2])
            num_diagonals = tryparse(Int, m[3])
            num_elements  = tryparse(Int, m[4])
            continue
        end

        # -*- Problem Term -*-
        m = match(r"^([+-]?[0-9]+)\s+([+-]?[0-9]+)\s+([+-]?([0-9]*[.])?[0-9]+)$", line)

        if !isnothing(m)
            i = tryparse(Int, m[1])
            j = tryparse(Int, m[2])
            Q = tryparse(Float64, m[3])

            if isnothing(i) || isnothing(j) || isnothing(Q)
                error("Error: $line")
            end

            if i == j
                linear_terms[i] = get(linear_terms, i, 0.0) + Q
            else
                quadratic_terms[(i, j)] = get(quadratic_terms, (i, j), 0.0) + Q
            end

            continue
        end

        error("Error: $line")
    end

    QUBO{BoolDomain}(
        id,
        scale,
        offset,
        max_index,
        num_diagonals,
        num_elements,
        linear_terms,
        quadratic_terms,
        metadata,
        description,
    )
end