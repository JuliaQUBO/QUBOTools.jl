const QUBO_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

@doc raw"""
""" struct QUBO{D<:BoolDomain} <: AbstractBQPModel{D}
    backend::QUBO_BACKEND_TYPE{D}
    max_index::Int
    num_diagonals::Int
    num_elements::Int

    function QUBO{D}(
        backend::QUBO_BACKEND_TYPE{D},
        max_index::Integer,
        num_diagonals::Integer,
        num_elements::Integer,
    ) where {D}

        new{D}(
            backend,
            max_index,
            num_diagonals,
            num_elements,
        )
    end

    function QUBO{D}(
        linear_terms::Dict{Int,Float64},
        quadratic_terms::Dict{Tuple{Int,Int},Float64},
        offset::Union{Float64,Nothing},
        scale::Union{Float64,Nothing},
        id::Union{Integer,Nothing},
        description::Union{String,Nothing},
        metadata::Union{Dict{String,Any},Nothing},
        max_index::Integer,
        num_diagonals::Integer,
        num_elements::Integer,
    ) where {D<:BoolDomain}
        variable_map, variable_inv = build_varbij(
            linear_terms,
            quadratic_terms
        )

        backend = QUBO_BACKEND_TYPE{D}(
            linear_terms,
            quadratic_terms,
            variable_map,
            variable_inv;
            offset=offset,
            scale=scale,
            id=id,
            description=description,
            metadata=metadata
        )

        QUBO{D}(
            backend,
            max_index,
            num_diagonals,
            num_elements,
        )
    end
end

function Base.write(io::IO, model::QUBO)
    println(io, "c ~*~ Generated with BQPIO.jl ~*~")
    if !isnothing(model.backend.id)
        println(io, "c id : $(model.backend.id)")
    end
    if !isnothing(model.backend.description)
        println(io, "c description : $(model.backend.description)")
    end
    if !isnothing(model.backend.offset)
        println(io, "c offset : $(model.backend.offset)")
    end
    if !isnothing(model.backend.scale)
        println(io, "c scale : $(model.backend.scale)")
    end
    if !isnothing(model.backend.metadata)
        for (k, v) in model.backend.metadata
            print(io, "c $(k) : ")
            JSON.print(io, v)
            println(io)
        end
    end
    println(io, "p qubo 0 $(model.max_index) $(model.num_diagonals) $(model.num_elements)")
    println(io, "c linear terms")
    for (i, q) in model.backend.linear_terms
        println(io, "$(i) $(i) $(q)")
    end
    println(io, "c quadratic terms")
    for ((i, j), Q) in model.backend.quadratic_terms
        println(io, "$(i) $(j) $(Q)")
    end
end

function Base.read(io::IO, ::Type{<:QUBO})
    linear_terms = Dict{Int,Float64}()
    quadratic_terms = Dict{Tuple{Int,Int},Float64}()

    offset = nothing
    scale = nothing

    id = nothing
    description = nothing
    metadata = Dict{String,Any}()

    max_index = nothing
    num_diagonals = nothing
    num_elements = nothing

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
            max_index = tryparse(Int, m[2])
            num_diagonals = tryparse(Int, m[3])
            num_elements = tryparse(Int, m[4])
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

    if isnothing(max_index) || isnothing(num_diagonals) || isnothing(num_elements)
        error("Error: Invalid problem header")
    end

    QUBO{BoolDomain}(
        linear_terms,
        quadratic_terms,
        offset,
        scale,
        id,
        description,
        metadata,
        max_index,
        num_diagonals,
        num_elements,
    )
end

function isvalidbridge(
    source::QUBO{D},
    target::QUBO{D},
    ::Type{<:QUBO{D}};
    kws...
) where {D<:BoolDomain}
    flag = true

    if source.max_index != target.max_index
        @error "Test Failure: Inconsistent maximum index"
        flag = false
    end

    if source.num_diagonals != target.num_diagonals
        @error "Test Failure: Inconsistent number of diagonals"
        flag = false
    end

    if source.num_elements != target.num_elements
        @error "Test Failure: Inconsistent number of elements"
        flag = false
    end

    if !isvalidbridge(
        source.backend,
        target.backend,
        QUBO_BACKEND_TYPE{D};
        kws...
    )
        flag = false
    end

    return flag
end