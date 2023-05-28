@doc raw"""
    Model{
        V <: Any,
        T <: Real,
        U <: Integer
    } <: AbstractModel{V,T,U}

The `Model` was designed to work as a general for all implemented interfaces.
It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP
Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

"""
mutable struct Model{V,T,U} <: AbstractModel{V,T,U}
    # Coefficients
    linear_terms::SparseVector{T}
    quadratic_terms::SparseMatrixCSC{T}
    # Variable Mapping
    variable_map::Dict{V,Int}
    variable_inv::Vector{V}
    # Factors
    scale::T
    offset::T
    # Sense & Domain
    sense::Sense
    domain::Domain
    # Metadata
    id::Union{Int,Nothing}
    description::Union{String,Nothing}
    metadata::Dict{String,Any}
    # Solutions
    warm_start::Vector{U}
    sampleset::SampleSet{T,U}

    function Model{V,T,U}(
        # Required data
        linear_terms::Dict{Int,T},
        quadratic_terms::Dict{Tuple{Int,Int},T},
        variable_map::Dict{V,Int},
        variable_inv::Dict{Int,V};
        # Factors
        scale::Union{T,Nothing}  = nothing,
        offset::Union{T,Nothing} = nothing,
        # Sense & Domain
        sense::Union{Sense,Nothing}   = nothing,
        domain::Union{Domain,Nothing} = nothing,
        # Metadata
        id::Union{Integer,Nothing}                = nothing,
        version::Union{VersionNumber,Nothing}     = nothing,
        description::Union{String,Nothing}        = nothing,
        metadata::Union{Dict{String,Any},Nothing} = nothing,
        # Solutions
        warm_start::Union{Dict{V,U},Nothing}     = nothing,
        sampleset::Union{SampleSet{T,U},Nothing} = nothing,
    ) where {V,T,U}
        scale      = isnothing(scale) ? one(T) : scale
        offset     = isnothing(offset) ? zero(T) : offset
        sense      = isnothing(sense) ? Min : Sense(sense)
        domain     = isnothing(domain) ? 𝔹 : Domain(domain)
        metadata   = isnothing(metadata) ? Dict{String,Any}() : metadata
        warm_start = isnothing(warm_start) ? Dict{V,U}() : warm_start
        sampleset  = isnothing(sampleset) ? SampleSet{T,U}() : sampleset

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
            warm_start,
            sampleset,
        )
    end
end

function Model{V,T,U}(
    # Required data
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

    linear_terms, quadratic_terms = _map_terms(
        _linear_terms,
        _quadratic_terms,
        variable_map,
    )

    return Model{V,T,U}(linear_terms, quadratic_terms, variable_map, variable_inv; kws...)
end

# Empty Constructor #
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
    # Structures #
    empty!(model.linear_terms)
    empty!(model.quadratic_terms)
    empty!(model.variable_map)
    empty!(model.variable_inv)

    # Attributes #
    model.scale       = one(T)
    model.offset      = zero(T)
    model.sense       = Sense(:min)
    model.domain      = nothing
    model.id          = nothing
    model.version     = nothing
    model.description = nothing
    empty!(model.metadata)
    empty!(model.warm_start)
    empty!(model.sampleset)

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
        warm_start  = deepcopy(warm_start(model)),
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
description(model::Model) = model.description
metadata(model::Model)    = model.metadata
warm_start(model::Model)  = model.warm_start
sampleset(model::Model)   = model.sampleset

function cast(route::Pair{X,Y}, model::Model{V,T,U}) where {V,T,U,X<:Domain,Y<:Domain}
    L, Q, α, β = cast(
        route,
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
        domain      = last(route), # target
        id          = id(model),
        description = description(model),
        metadata    = metadata(model),
        sampleset   = cast(route, sampleset(model)),
    )
end

function cast(route::Pair{A,B}, model::Model{V,T,U}) where {V,T,U,A<:Sense,B<:Sense}
    L, Q, α, β = cast(
        route,
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
        sense       = last(route), #target
        domain      = domain(model),
        id          = id(model),
        description = description(model),
        metadata    = deepcopy(metadata(model)),
        sampleset   = cast(route, sampleset(model)),
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
    target.description     = description(source)
    target.metadata        = deepcopy(metadata(source))
    target.warm_start      = deepcopy(warm_start(source))
    target.sampleset       = copy(sampleset(source))

    return target
end
