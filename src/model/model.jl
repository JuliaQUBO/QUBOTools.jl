@doc raw"""
    Model{
        D <: VariableDomain,
        V <: Any,
        T <: Real,
        U <: Integer
    } <: AbstractModel{D}

The `Model` was designed to work as a general for all implemented interfaces.
It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP
Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

""" mutable struct Model{D<:VariableDomain,V<:Any,T<:Real,U<:Integer} <: AbstractModel{D}
    # ~*~ Required data ~*~
    linear_terms::Dict{Int,T}
    quadratic_terms::Dict{Tuple{Int,Int},T}
    variable_map::Dict{V,Int}
    variable_inv::Dict{Int,V}
    # ~*~ Factors ~*~
    scale::T
    offset::T
    # ~*~ Sense ~*~
    sense::Symbol
    # ~*~ Metadata ~*~
    id::Union{Int,Nothing}
    version::Union{VersionNumber,Nothing}
    description::Union{String,Nothing}
    metadata::Union{Dict{String,Any},Nothing}
    # ~*~ Solutions ~*~
    sampleset::Union{SampleSet{T,U},Nothing}

    function Model{D,V,T,U}(
        # ~*~ Required data ~*~
        linear_terms::Dict{Int,T},
        quadratic_terms::Dict{Tuple{Int,Int},T},
        variable_map::Dict{V,Int},
        variable_inv::Dict{Int,V};
        # ~*~ Factors ~*~
        scale::Union{T,Nothing} = nothing,
        offset::Union{T,Nothing} = nothing,
        # ~*~ Sense ~*~
        sense::Union{Symbol,Nothing} = nothing,
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
            something(scale, one(T)),
            something(offset, zero(T)),
            something(sense, :min),
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end
end

function Model{D,V,T,U}(
    # ~*~ Required data ~*~
    _linear_terms::Dict{V,T},
    _quadratic_terms::Dict{Tuple{V,V},T},
    _variable_set::Union{Set{V},Nothing} = nothing;
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

    if isnothing(_variable_set)
        _variable_set = variable_set
    elseif !issubset(variable_set, _variable_set)
        error("'variable_set' is not a subset of '_variable_set'")
    end

    variable_map, variable_inv = QUBOTools._build_mapping(_variable_set)

    linear_terms, quadratic_terms =
        QUBOTools._map_terms(_linear_terms, _quadratic_terms, variable_map)

    return Model{D,V,T,U}(linear_terms, quadratic_terms, variable_map, variable_inv; kws...)
end

function Model{D,V,T,U}(; kws...) where {D,V,T,U}
    return Model{D,V,T,U}(Dict{V,T}(), Dict{Tuple{V,V},T}(); kws...)
end

function Model{D,V,T}(args...; kws...) where {D,V,T}
    return Model{D,V,T,Int}(args...; kws...)
end

function Model{D,V}(args...; kws...) where {D,V}
    return Model{D,V,Float64,Int}(args...; kws...)
end

function Model{D}(args...; kws...) where {D}
    return Model{D,Int,Float64,Int}(args...; kws...)
end

function Base.empty!(model::Model{D,V,T,U}) where {D,V,T,U}
    # ~*~ Structures ~*~ #
    empty!(model.linear_terms)
    empty!(model.quadratic_terms)
    empty!(model.variable_map)
    empty!(model.variable_inv)

    # ~*~ Attributes ~*~ #
    model.scale       = one(T)
    model.offset      = zero(T)
    model.sense       = :min
    model.id          = nothing
    model.version     = nothing
    model.description = nothing
    model.metadata    = nothing
    model.sampleset   = nothing

    return model
end

function Base.isempty(model::Model)
    return isempty(model.variable_map) && isempty(model.variable_inv)
end

function Base.copy(model::Model{D,V,T,U}) where {D,V,T,U}
    return Model{D,V,T,U}(
        copy(model.linear_terms),
        copy(model.quadratic_terms),
        copy(model.variable_map),
        copy(model.variable_inv);
        scale       = model.scale,
        offset      = model.offset,
        sense       = model.sense,
        id          = model.id,
        version     = model.version,
        description = model.description,
        metadata    = deepcopy(model.metadata),
        sampleset   = model.sampleset,
    )
end

scale(model::Model)  = model.scale
offset(model::Model) = model.offset
sense(model::Model)  = model.sense

linear_terms(model::Model)    = model.linear_terms
quadratic_terms(model::Model) = model.quadratic_terms
variable_map(model::Model)    = model.variable_map
variable_inv(model::Model)    = model.variable_inv

id(model::Model)          = model.id
version(model::Model)     = model.version
description(model::Model) = model.description
metadata(model::Model)    = model.metadata
sampleset(model::Model)   = model.sampleset

function swap_domain(::D, ::D, model::Model{D}) where {D<:VariableDomain}
    return model
end

function swap_domain(::X, ::Y, model::Model{X,V,T,U}) where {X,Y,V,T,U}
    L, Q, α, β = swap_domain(
        X(),
        Y(),
        linear_terms(model),
        quadratic_terms(model),
        scale(model),
        offset(model),
    )

    ω = sampleset(model)

    if isnothing(ω)
        η = nothing
    else
        η = swap_domain(X(), Y(), sampleset(model))
    end

    return Model{Y,V,T,U}(
        L,
        Q;
        scale       = α,
        offset      = β,
        id          = id(model),
        version     = version(model),
        description = description(model),
        metadata    = metadata(model),
        sampleset   = η,
    )
end

function Base.copy!(target::Model{D,V,T,U}, source::Model{D,V,T,U}) where {D,V,T,U}
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

function Base.copy!(target::Model{B,V,T,U}, source::Model{A,V,T,U}) where {A,B,V,T,U}
    return copy!(target, convert(Model{B,V,T,U}, source))
end

function Base.convert(::Type{Model{Y,V,T,U}}, model::Model{X,V,T,U}) where {X,Y,V,T,U}
    return swap_domain(X(), Y(), model)
end

const StandardModel{D} = Model{D,Int,Float64,Int}