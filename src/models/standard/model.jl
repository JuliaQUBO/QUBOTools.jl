@doc raw"""
    StandardQUBOModel{
        D <: VariableDomain,
        V <: Any,
        T <: Real,
        U <: Integer
    } <: AbstractQUBOModel{D}

The `StandardQUBOModel` was designed to work as a general for all implemented interfaces.
It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP
Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

""" mutable struct StandardQUBOModel{D<:VariableDomain,V<:Any,T<:Real,U<:Integer} <:
                   AbstractQUBOModel{D}
    # ~*~ Required data ~*~
    linear_terms::Dict{Int,T}
    quadratic_terms::Dict{Tuple{Int,Int},T}
    variable_map::Dict{V,Int}
    variable_inv::Dict{Int,V}
    # ~*~ Factors ~*~
    offset::Union{T,Nothing}
    scale::Union{T,Nothing}
    # ~*~ Metadata ~*~
    id::Union{Int,Nothing}
    version::Union{VersionNumber,Nothing}
    description::Union{String,Nothing}
    metadata::Union{Dict{String,Any},Nothing}
    # ~*~ Solutions ~*~
    sampleset::Union{SampleSet{T,U},Nothing}

    function StandardQUBOModel{D,V,T,U}(
        # ~*~ Required data ~*~
        linear_terms::Dict{Int,T},
        quadratic_terms::Dict{Tuple{Int,Int},T},
        variable_map::Dict{V,Int},
        variable_inv::Dict{Int,V};
        # ~*~ Factors ~*~
        offset::Union{T,Nothing} = nothing,
        scale::Union{T,Nothing} = nothing,
        # ~*~ Metadata ~*~
        id::Union{Integer,Nothing} = nothing,
        version::Union{VersionNumber,Nothing} = nothing,
        description::Union{String,Nothing} = nothing,
        metadata::Union{Dict{String,Any},Nothing} = nothing,
        # ~*~ Solutions ~*~
        sampleset::Union{SampleSet{T,U},Nothing} = nothing,
    ) where {D,V,T,U}
        new{D,V,T,U}(
            linear_terms,
            quadratic_terms,
            variable_map,
            variable_inv,
            offset,
            scale,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end

    function StandardQUBOModel{D,V,T,U}(
        # ~*~ Required data ~*~
        _linear_terms::Dict{V,T},
        _quadratic_terms::Dict{Tuple{V,V},T};
        kws...,
    ) where {D,V,T,U}
        # ~ What is happening now: There were many layers of validation
        #   before we got here. This call to `_normal_form` removes any re-
        #   dundancy by aggregating (i, j) and (j, i) terms and also ma-
        #   king "quadratic" terms with i == j  into linear ones. Also,
        #   zeros are removed, improving sparsity in this last step.
        # ~ New objects are created not to disturb the original ones.
        _linear_terms, _quadratic_terms, variable_set =
            QUBOTools._normal_form(_linear_terms, _quadratic_terms)

        variable_map, variable_inv = QUBOTools._build_mapping(variable_set)

        linear_terms, quadratic_terms =
            QUBOTools._map_terms(_linear_terms, _quadratic_terms, variable_map)

        StandardQUBOModel{D,V,T,U}(
            linear_terms,
            quadratic_terms,
            variable_map,
            variable_inv;
            kws...,
        )
    end

    function StandardQUBOModel{D,V,T,U}(; kws...) where {D,V,T,U}
        return StandardQUBOModel{D,V,T,U}(Dict{V,T}(), Dict{Tuple{V,V},T}(); kws...)
    end
end

function StandardQUBOModel{D,V,T}(args...; kws...) where {D,V,T}
    return StandardQUBOModel{D,V,T,Int}(args...; kws...)
end

function StandardQUBOModel{D,V}(args...; kws...) where {D,V}
    return StandardQUBOModel{D,V,Float64}(args...; kws...)
end

function StandardQUBOModel{D}(args...; kws...) where {D}
    return StandardQUBOModel{D,Int}(args...; kws...)
end

function Base.empty!(model::StandardQUBOModel)
    # ~*~ Structures ~*~ #
    empty!(model.linear_terms)
    empty!(model.quadratic_terms)
    empty!(model.variable_map)
    empty!(model.variable_inv)

    # ~*~ Attributes ~*~ #
    model.scale       = nothing
    model.offset      = nothing
    model.id          = nothing
    model.version     = nothing
    model.description = nothing
    model.metadata    = nothing
    model.sampleset   = nothing

    return model
end

function Base.isempty(model::StandardQUBOModel)
    return isempty(model.variable_map) && isempty(model.variable_inv)
end

function Base.copy(model::StandardQUBOModel{D,V,T,U}) where {D,V,T,U}
    return StandardQUBOModel{D,V,T,U}(
        copy(model.linear_terms),
        copy(model.quadratic_terms),
        copy(model.variable_map),
        copy(model.variable_inv);
        offset      = model.offset,
        scale       = model.scale,
        id          = model.id,
        version     = model.version,
        description = model.description,
        metadata    = deepcopy(model.metadata),
        sampleset   = model.sampleset,
    )
end

# This is important to avoid infinite recursion on fallback implementations
backend(::StandardQUBOModel) = nothing

function QUBOTools.scale(model::StandardQUBOModel{<:Any,<:Any,T,<:Any}) where {T}
    if isnothing(model.scale)
        return one(T)
    else
        return model.scale
    end
end

function QUBOTools.offset(model::StandardQUBOModel{<:Any,<:Any,T,<:Any}) where {T}
    if isnothing(model.offset)
        return zero(T)
    else
        return model.offset
    end
end

linear_terms(model::StandardQUBOModel)    = model.linear_terms
quadratic_terms(model::StandardQUBOModel) = model.quadratic_terms
variable_map(model::StandardQUBOModel)    = model.variable_map
variable_inv(model::StandardQUBOModel)    = model.variable_inv

id(model::StandardQUBOModel)          = model.id
version(model::StandardQUBOModel)     = model.version
description(model::StandardQUBOModel) = model.description
metadata(model::StandardQUBOModel)    = model.metadata
sampleset(model::StandardQUBOModel)   = model.sampleset

function bridge(
    ::Type{StandardQUBOModel{B,V,T,U}},
    model::StandardQUBOModel{A,V,T,U},
) where {A,B,V,T,U}
    _linear_terms, _quadratic_terms, offset = QUBOTools._swapdomain(
        A(),
        B(),
        model.linear_terms,
        model.quadratic_terms,
        model.offset,
    )

    linear_terms, quadratic_terms, _ = QUBOTools._normal_form(
        _linear_terms,
        _quadratic_terms,
    )

    return StandardQUBOModel{B,V,T,U}(
        linear_terms,
        quadratic_terms,
        copy(model.variable_map),
        copy(model.variable_inv);
        scale       = model.scale,
        offset      = offset,
        id          = model.id,
        version     = model.version,
        description = model.description,
        metadata    = deepcopy(model.metadata),
        sampleset   = model.sampleset,
    )
end

function Base.copy!(
    target::StandardQUBOModel{D,V,T,U},
    source::StandardQUBOModel{D,V,T,U},
) where {D,V,T,U}
    target.linear_terms    = copy(source.linear_terms)
    target.quadratic_terms = copy(source.quadratic_terms)
    target.variable_map    = copy(source.variable_map)
    target.variable_inv    = copy(source.variable_inv)
    target.scale           = source.scale
    target.offset          = source.offset
    target.id              = source.id
    target.version         = source.version
    target.description     = source.description
    target.metadata        = deepcopy(source.metadata)
    target.sampleset       = source.sampleset

    return target
end

function Base.copy!(
    target::StandardQUBOModel{B,V,T,U},
    source::StandardQUBOModel{A,V,T,U},
) where {A,B,V,T,U}
    return copy!(target, convert(StandardQUBOModel{B,V,T,U}, source))
end