

@doc raw"""
""" mutable struct StandardBQPModel{
        S <: Any,
        U <: Integer,
        T <: Real,
        D <: VariableDomain
        } <: AbstractBQPModel{D}
    # ~*~ Required data ~*~
    linear_terms::Dict{Int,T}
    quadratic_terms::Dict{Tuple{Int,Int},T}
    offset::T
    scale::T
    variable_map::Dict{S, Int}
    variable_inv::Dict{Int, S}
    # ~*~ Metadata ~*~
    id::Union{Int, Nothing}
    version::Union{VersionNumber, Nothing}
    description::Union{String, Nothing}
    metadata::Dict{String,Any}
    # ~*~ Solutions ~*~
    sampleset::Union{SampleSet{U, T}, Nothing}

    function StandardBQPModel{S, U, T, D}(
        linear_terms::Dict{Int, T},
        quadratic_terms::Dict{Tuple{Int, Int}, T},
        offset::T,
        scale::T,
        variable_map::Dict{S, Int},
        variable_inv::Dict{Int, S},
        id::Union{Integer, Nothing},
        version::Union{VersionNumber, Nothing},
        description::Union{String, Nothing},
        metadata::Dict{String, Any},
        sampleset::Union{SampleSet{U, T}, Nothing},
        ) where {S, U, T, D}

        new{S, U, T, D}(
            linear_terms,
            quadratic_terms,
            offset,
            scale,
            variable_map,
            variable_inv,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end

    function StandardBQPModel{S, U, T, D}(
        linear_terms::Dict{Int, T},
        quadratic_terms::Dict{Tuple{Int, Int}, T},
        offset::T,
        scale::T,
        variable_map::Dict{S, Int},
        id::Union{Integer, Nothing} = nothing,
        version::Union{VersionNumber, Nothing} = nothing,
        description::Union{String, Nothing} = nothing,
        metadata::Union{Dict{String, Any}, Nothing} = nothing,
        sampleset::Union{SampleSet{U, T}, Nothing} = nothing,
        ) where {S, U, T, D}

        variable_inv = Dict{Int, S}(v => k for (k, v) in variable_map)

        if isnothing(metadata)
            metadata = Dict{String, Any}()
        end

        StandardBQPModel{S, U, T, D}(
            linear_terms,
            quadratic_terms,
            offset,
            scale,
            variable_map,
            variable_inv,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end

    function StandardBQPModel{S, T, D}(
        linear_terms::Dict{Int, T},
        quadratic_terms::Dict{Tuple{Int, Int}, T},
        offset::T,
        scale::T,
        variable_map::Dict{S, Int},
        id::Union{Integer, Nothing} = nothing,
        version::Union{VersionNumber, Nothing} = nothing,
        description::Union{String, Nothing} = nothing,
        metadata::Union{Dict{String, Any}, Nothing} = nothing,
        sampleset::Union{SampleSet{Int, T}, Nothing} = nothing,
        ) where {S, T, D}

        StandardBQPModel{S, Int, T, D}(
            linear_terms,
            quadratic_terms,
            offset,
            scale,
            variable_map,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end

    function StandardBQPModel{D}(
        linear_terms::Dict{Int, Float64},
        quadratic_terms::Dict{Tuple{Int, Int}, Float64},
        offset::Float64,
        scale::Float64,
        id::Union{Integer, Nothing} = nothing,
        version::Union{VersionNumber, Nothing} = nothing,
        description::Union{String, Nothing} = nothing,
        metadata::Union{Dict{String, Any}, Nothing} = nothing,
        sampleset::Union{SampleSet{Int, Float64}, Nothing} = nothing,
        ) where {D <: VariableDomain}

        variables = Set{Int}()

        for i in keys(linear_terms)
            push!(variables, i)
        end

        for (i, j) in keys(quadratic_terms)
            push!(variables, i, j)
        end

        variable_map = Dict{Int, Int}(
            i => k for (k, i) in enumerate(sort(collect(variables)))
        )

        StandardBQPModel{Int, Int, Float64, D}(
            linear_terms,
            quadratic_terms,
            offset,
            scale,
            variable_map,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end
end

function Base.copy(model::StandardBQPModel{S, U, T, D}) where {S, U, T, D}
    StandardBQPModel{S, U, T, D}(
        copy(model.linear_terms),
        copy(model.quadratic_terms),
        model.offset,
        model.scale,
        copy(model.variable_map),
        copy(model.variable_inv),
        model.id,
        model.version,
        model.description,
        deepcopy(model.metadata),
        model.sampleset,
    )
end

function Base.convert(
    ::Type{<:StandardBQPModel{S, U, T, D}},
    model::StandardBQPModel{S, U, T, D},
    ) where {S, U, T, D}
    model # Short-circuit! Yeah!
end

function Base.convert(
        ::Type{<:StandardBQPModel{S, U, T, B}},
        model::StandardBQPModel{S, U, T, A},
    ) where {S, U, T, A, B}

    offset, linear_terms, quadratic_terms = swapdomain(
        A,
        B,
        model.offset,
        model.linear_terms,
        model.quadratic_terms,
    )

    StandardBQPModel{S, U, T, B}(
        linear_terms,
        quadratic_terms,
        offset,
        model.scale,
        copy(model.variable_map),
        copy(model.variable_inv),
        model.id,
        model.version,
        model.description,
        deepcopy(model.metadata),
        model.sampleset,
    )
end

# function Base.write(io::IO, model::BQPModel) end
# function Base.read(io::IO, ::Type{<:BQPModel}) end