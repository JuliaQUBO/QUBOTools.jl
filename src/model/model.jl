@doc raw"""
    Model{
        V <: Any,
        T <: Real,
        U <: Integer
    } <: AbstractModel{V,T}

The `Model` was designed to work as a general for all implemented interfaces.
It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP
Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

""" mutable struct Model{V<:Any,T<:Real,U<:Integer} <: AbstractModel{V,T}
    # ~*~ Required data ~*~
    linear_terms::Dict{Int,T}
    quadratic_terms::Dict{Tuple{Int,Int},T}
    variable_map::Dict{V,Int}
    variable_inv::Dict{Int,V}
    # ~*~ Factors ~*~
    scale::T
    offset::T
    # ~*~ Sense & Domain ~*~
    sense::Sense
    domain::Union{Domain,Nothing}
    # ~*~ Metadata ~*~
    id::Union{Int,Nothing}
    version::Union{VersionNumber,Nothing}
    description::Union{String,Nothing}
    metadata::Union{Dict{String,Any},Nothing}
    # ~*~ Solutions ~*~
    sampleset::SampleSet{T,U}

    function Model{V,T,U}(
        # ~*~ Required data ~*~
        linear_terms::Dict{Int,T},
        quadratic_terms::Dict{Tuple{Int,Int},T},
        variable_map::Dict{V,Int},
        variable_inv::Dict{Int,V};
        # ~*~ Factors ~*~
        scale::Union{T,Nothing}  = nothing,
        offset::Union{T,Nothing} = nothing,
        # ~*~ Sense & Domain ~*~
        sense::Union{Sense,Symbol,Nothing}   = nothing,
        domain::Union{Domain,Symbol,Nothing} = nothing,
        # ~*~ Metadata ~*~
        id::Union{Integer,Nothing}                = nothing,
        version::Union{VersionNumber,Nothing}     = nothing,
        description::Union{String,Nothing}        = nothing,
        metadata::Union{Dict{String,Any},Nothing} = nothing,
        # ~*~ Solutions ~*~
        sampleset::Union{SampleSet{T,U},Nothing} = nothing,
    ) where {V,T,U}
        scale     = isnothing(scale)     ? one(T)           : scale
        offset    = isnothing(offset)    ? zero(T)          : offset
        sense     = isnothing(sense)     ? Sense(:min)      : Sense(sense)
        domain    = isnothing(domain)    ? nothing          : Domain(domain)
        sampleset = isnothing(sampleset) ? SampleSet{T,U}() : sampleset

        return new{V,T,U}(
            linear_terms,
            quadratic_terms,
            variable_map,
            variable_inv,
            scale,
            offset,
            sense,
            domain,
            id,
            version,
            description,
            metadata,
            sampleset,
        )
    end
end

function Model{V,T,U}(
    # ~*~ Required data ~*~
    _linear_terms::Dict{V,T},
    _quadratic_terms::Dict{Tuple{V,V},T},
    _variable_set::Union{Set{V},Nothing} = nothing;
    kws...,
) where {V,T,U}
    # ~ What is happening now: There were many layers of validation
    #   before we got here. This call to `_normal_form` removes any
    #   redundancy by aggregating (i, j) and (j, i) terms and also 
    #   making "quadratic" terms with i == j  into linear ones.
    #   Also, zeros are removed, improving sparsity in this last step.
    # ~ New objects are created not to disturb the original ones.
    _linear_terms, _quadratic_terms, variable_set =
        _normal_form(_linear_terms, _quadratic_terms)

    if isnothing(_variable_set)
        _variable_set = variable_set
    elseif !issubset(variable_set, _variable_set)
        error("'variable_set' is not a subset of '_variable_set'")
    end

    variable_map, variable_inv = _build_mapping(_variable_set)

    linear_terms, quadratic_terms =
        _map_terms(_linear_terms, _quadratic_terms, variable_map)

    return Model{V,T,U}(linear_terms, quadratic_terms, variable_map, variable_inv; kws...)
end

# ~*~ Empty Constructor ~*~ #
function Model{V,T,U}(; kws...) where {V,T,U}
    return Model{V,T,U}(Dict{V,T}(), Dict{Tuple{V,V},T}(); kws...)
end

function Model{V,T}(args...; kws...) where {V,T}
    return Model{V,T,Int}(args...; kws...)
end

function Model{V}(args...; kws...) where {V}
    return Model{V,Float64,Int}(args...; kws...)
end

function Base.empty!(model::Model{V,T,U}) where {V,T,U}
    # ~*~ Structures ~*~ #
    empty!(model.linear_terms)
    empty!(model.quadratic_terms)
    empty!(model.variable_map)
    empty!(model.variable_inv)

    # ~*~ Attributes ~*~ #
    model.scale       = one(T)
    model.offset      = zero(T)
    model.sense       = Sense(:min)
    model.domain      = nothing
    model.id          = nothing
    model.version     = nothing
    model.description = nothing
    model.metadata    = nothing
    model.sampleset   = SampleSet{T,U}()

    return model
end

function Base.isempty(model::Model)
    return isempty(model.variable_map) && isempty(model.variable_inv)
end

function Base.copy(model::Model{V,T,U}) where {V,T,U}
    return Model{V,T,U}(
        copy(linear_terms(model)),
        copy(quadratic_terms(model)),
        copy(variable_map(model)),
        copy(variable_inv(model));
        scale       = scale(model),
        offset      = offset(model),
        sense       = sense(model),
        domain      = domain(model),
        id          = id(model),
        version     = version(model),
        description = description(model),
        metadata    = deepcopy(metadata(model)),
        sampleset   = copy(sampleset(model)),
    )
end

scale(model::Model)  = model.scale
offset(model::Model) = model.offset
sense(model::Model)  = model.sense
domain(model::Model) = model.domain

linear_terms(model::Model)    = model.linear_terms
quadratic_terms(model::Model) = model.quadratic_terms
variable_map(model::Model)    = model.variable_map
variable_inv(model::Model)    = model.variable_inv

id(model::Model)          = model.id
version(model::Model)     = model.version
description(model::Model) = model.description
metadata(model::Model)    = model.metadata
sampleset(model::Model)   = model.sampleset

function swap_domain(target::Domain, model::Model{V,T,U}) where {V,T,U}
    source = domain(model)

    L, Q, α, β = swap_domain(
        source,
        target,
        linear_terms(model),
        quadratic_terms(model),
        scale(model),
        offset(model),
    )

    return Model{V,T,U}(
        L,
        Q,
        copy(variable_map(model)),
        copy(variable_inv(model));
        scale       = α,
        offset      = β,
        sense       = sense(model),
        domain      = target,
        id          = id(model),
        version     = version(model),
        description = description(model),
        metadata    = metadata(model),
        sampleset   = swap_domain(source, target, sampleset(model)),
    )
end

function swap_sense(model::Model{V,T,U}) where {V,T,U}
    return Model{V,T,U}(
        swap_sense(linear_terms(model)),
        swap_sense(quadratic_terms(model)),
        copy(variable_map(model)),
        copy(variable_inv(model));
        scale       = scale(model),
        offset      = -offset(model),
        sense       = swap_sense(sense(model)),
        domain      = domain(model),
        id          = id(model),
        version     = version(model),
        description = description(model),
        metadata    = deepcopy(metadata(model)),
        sampleset   = swap_sense(sampleset(model)),
    )
end

function Base.copy!(target::Model{V,T,U}, source::Model{V,T,U}) where {V,T,U}
    target.linear_terms    = copy(linear_terms(source))
    target.quadratic_terms = copy(quadratic_terms(source))
    target.variable_map    = copy(variable_map(source))
    target.variable_inv    = copy(variable_inv(source))
    target.scale           = scale(source)
    target.offset          = offset(source)
    target.sense           = sense(source)
    target.domain          = domain(source)
    target.id              = id(source)
    target.version         = version(source)
    target.description     = description(source)
    target.metadata        = deepcopy(metadata(source))
    target.sampleset       = copy(sampleset(source))

    return target
end

const StandardModel = Model{Int,Float64,Int}