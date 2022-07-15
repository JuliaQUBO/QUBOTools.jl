const QUBO_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

@doc raw"""
""" mutable struct QUBO{D<:BoolDomain} <: AbstractBQPModel{D}
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
        BQPIO.backend(source),
        BQPIO.backend(target),
        QUBO_BACKEND_TYPE{D};
        kws...
    )
        flag = false
    end

    return flag
end