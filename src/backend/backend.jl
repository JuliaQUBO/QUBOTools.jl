@doc raw"""
    StandardQUBOModel{
        V <: Any,
        U <: Integer,
        T <: Real,
        D <: VariableDomain
    } <: AbstractQUBOModel{D}

The `StandardQUBOModel` was designed to work as a general for all implemented interfaces.
It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP
Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

""" mutable struct StandardQUBOModel{
    V<:Any,
    U<:Integer,
    T<:Real,
    D<:VariableDomain
} <: AbstractQUBOModel{D}
    # ~*~ Required data ~*~
    linear_terms::Dict{Int,T}
    quadratic_terms::Dict{Tuple{Int,Int},T}
    variable_map::Dict{V,Int}
    variable_inv::Dict{Int,V}
    # ~*~ Sense ~*~
    sense::Symbol
    # ~*~ Factors ~*~
    offset::Union{T,Nothing}
    scale::Union{T,Nothing}
    # ~*~ Metadata ~*~
    id::Union{Int,Nothing}
    version::Union{VersionNumber,Nothing}
    description::Union{String,Nothing}
    metadata::Union{Dict{String,Any},Nothing}
    # ~*~ Solutions ~*~
    sampleset::Union{SampleSet{U,T},Nothing}

    function StandardQUBOModel{V,U,T,D}(
        # ~*~ Required data ~*~
        linear_terms::Dict{Int,T},
        quadratic_terms::Dict{Tuple{Int,Int},T},
        variable_map::Dict{V,Int},
        variable_inv::Dict{Int,V};
        # ~*~ Sense ~*~
        sense::Symbol=:min,
        # ~*~ Factors ~*~
        offset::Union{T,Nothing}=nothing,
        scale::Union{T,Nothing}=nothing,
        # ~*~ Metadata ~*~
        id::Union{Integer,Nothing}=nothing,
        version::Union{VersionNumber,Nothing}=nothing,
        description::Union{String,Nothing}=nothing,
        metadata::Union{Dict{String,Any},Nothing}=nothing,
        # ~*~ Solutions ~*~
        sampleset::Union{SampleSet{U,T},Nothing}=nothing
    ) where {V,U,T,D}
        @assert sense === :min || sense === :max

        new{V,U,T,D}(
            linear_terms,
            quadratic_terms,
            variable_map,
            variable_inv,
            sense,
            offset,
            scale,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end

    function StandardQUBOModel{V,U,T,D}(
        # ~*~ Required data ~*~
        _linear_terms::Dict{V,T},
        _quadratic_terms::Dict{Tuple{V,V},T};
        kws...
    ) where {V,U,T,D}
        # ~ What is happening now: There were many layers of validation
        #   before we got here. This call to `_normal_form` removes any re-
        #   dundancy by aggregating (i, j) and (j, i) terms and also ma-
        #   king "quadratic" terms with i == j  into linear ones. Also,
        #   zeros are removed, improving sparsity in this last step.
        # ~ New objects are created not to disturb the original ones.
        _linear_terms, _quadratic_terms, variable_set = QUBOTools._normal_form(
            _linear_terms,
            _quadratic_terms,
        )

        variable_map, variable_inv = QUBOTools._build_mapping(variable_set)

        linear_terms, quadratic_terms = QUBOTools._map_terms(
            _linear_terms,
            _quadratic_terms,
            variable_map,
        )

        StandardQUBOModel{V,U,T,D}(
            linear_terms,
            quadratic_terms,
            variable_map,
            variable_inv;
            kws...
        )
    end

    function StandardQUBOModel{V,U,T,D}(; kws...) where {V,U,T,D}
        StandardQUBOModel{V,U,T,D}(
            Dict{V,T}(),
            Dict{Tuple{V,V},T}();
            kws...
        )
    end

    # ~ aliasing ~
    function StandardQUBOModel{V,T,D}(args...; kws...) where {V,T,D}
        StandardQUBOModel{V,Int,T,D}(args...; kws...)
    end

    function StandardQUBOModel{V,D}(args...; kws...) where {V,D}
        StandardQUBOModel{V,Int,Float64,D}(args...; kws...)
    end

    function StandardQUBOModel{D}(args...; kws...) where {D}
        StandardQUBOModel{Int,Int,Float64,D}(args...; kws...)
    end
end

function Base.empty!(model::StandardQUBOModel)
    empty!(model.linear_terms)
    empty!(model.quadratic_terms)
    empty!(model.variable_map)
    empty!(model.variable_inv)
    model.offset = nothing
    model.scale = nothing
    model.id = nothing
    model.version = nothing
    model.description = nothing
    model.metadata = nothing
    model.sampleset = nothing

    return model
end

function Base.isempty(model::StandardQUBOModel)
    return isempty(model.linear_terms) &&
           isempty(model.quadratic_terms) &&
           isempty(model.variable_map) &&
           isempty(model.variable_inv) &&
           isnothing(model.offset) &&
           isnothing(model.scale) &&
           isnothing(model.id) &&
           isnothing(model.version) &&
           isnothing(model.description) &&
           isnothing(model.metadata) &&
           isnothing(model.sampleset)
end

function Base.copy(model::StandardQUBOModel{V,U,T,D}) where {V,U,T,D}
    StandardQUBOModel{V,U,T,D}(
        copy(model.linear_terms),
        copy(model.quadratic_terms),
        copy(model.variable_map),
        copy(model.variable_inv);
        offset=model.offset,
        scale=model.scale,
        id=model.id,
        version=model.version,
        description=model.description,
        metadata=deepcopy(model.metadata),
        sampleset=model.sampleset
    )
end

function QUBOTools.__isvalidbridge(
    source::StandardQUBOModel{V,U,T,D},
    target::StandardQUBOModel{V,U,T,D};
    kws...
) where {V,U,T,D}
    flag = true

    if !isnothing(source.id) && !isnothing(target.id) && (source.id != target.id)
        @error """
        Test Failure: ID mismatch:
        $(source.id) ≂̸ $(target.id)
        """
        flag = false
    end

    if !isnothing(source.description) && !isnothing(target.description) && (source.description != target.description)
        @error """
        Test Failure: Description mismatch:
        $(source.description) ≂̸ $(target.description)
        """
        flag = false
    end

    if !isnothing(source.metadata) && !isnothing(target.metadata) && (source.metadata != target.metadata)
        @error "Test Failure: Metadata mismatch"
        flag = false
    end

    if !isapproxdict(source.linear_terms, target.linear_terms; kws...)
        @error """
        Test Failure: Linear terms mismatch:
        $(source.linear_terms) ≉ $(target.linear_terms)
        """
        flag = false
    end

    if !isapproxdict(source.quadratic_terms, target.quadratic_terms; kws...)
        @error """
        Test Failure: Quadratic terms mismatch:
        $(source.quadratic_terms) ≉ $(target.quadratic_terms)
        """
        flag = false
    end

    if !isnothing(source.offset) && !isnothing(target.offset) && !isapprox(source.offset, target.offset; kws...)
        @error """
        Test Failure: Offset mismatch:
        $(source.offset) ≂̸ $(target.offset)
        """
        flag = false
    end

    if !isnothing(source.scale) && !isnothing(target.scale) && !isapprox(source.scale, target.scale; kws...)
        @error """
        Test Failure: Scale mismatch:
        $(source.scale) ≠ $(target.scale)
        """
        flag = false
    end

    return flag
end

include("data.jl")
include("io.jl")