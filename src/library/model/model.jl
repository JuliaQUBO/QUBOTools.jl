@doc raw"""
    Model{V,T,U,F<:AbstractForm{T}} <: AbstractModel{V,T,U}

Reference [`AbstractModel`](@ref) implementation.
It is intended to be the stardard in-memory representation for QUBO models.

## [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)/[JuMP](https://jump.dev) Integration

Both `V` and `T` parameters exist to support MathOptInterface/JuMP integration.
This is made possible by choosing `V` to match `MOI.VariableIndex` and `T` as in `Optimizer{T}`.
"""
mutable struct Model{V,T,U,F<:AbstractForm{T}} <: AbstractModel{V,T,U}
    # Variable Mapping
    variable_map::VariableMap{V}
    # Coefficients, Factors & Frame
    form::F
    # Metadata
    metadata::Dict{String,Any}
    # Solution
    solution::SampleSet{T,U}
    # Hints
    start::Dict{Int,U}

    # Canonical Constructor - Normal Form
    function Model{V,T,U}(
        variable_map::VariableMap{V},
        form::F;
        metadata::Union{Dict{String,Any},Nothing} = nothing,
        solution::Union{SampleSet{T,U},Nothing} = nothing,
        start::Union{Dict{Int,U},Nothing} = nothing,
        # Extra Metadata
        id::Union{Integer,Nothing} = nothing,
        description::Union{String,Nothing} = nothing,
    ) where {V,T,U,F<:AbstractForm{T}}
        if isnothing(metadata)
            metadata = Dict{String,Any}()
        end

        if isnothing(solution)
            solution = SampleSet{T,U}()
        end

        if isnothing(start)
            start = Dict{Int,U}()
        end

        if !isnothing(id)
            metadata["id"] = id
        end

        if !isnothing(description)
            metadata["description"] = description
        end

        return new{V,T,U,F}(variable_map, form, metadata, solution, start)
    end
end

# Empty Model
function Model{V,T,U}(;
    scale::T = one(T),
    offset::T = zero(T),
    sense::Union{Sense,Symbol} = :min,
    domain::Union{Domain,Symbol} = :bool,
    metadata::Union{Dict{String,Any},Nothing} = nothing,
    solution::Union{SampleSet{T,U},Nothing} = nothing,
    start::Union{Dict{Int,U},Nothing} = nothing,
    # Extra Metadata
    id::Union{Integer,Nothing} = nothing,
    description::Union{String,Nothing} = nothing,
) where {V,T,U}
    variables_map = VariableMap{V}(V[])

    form = Form{T}(
        0,
        SparseLinearForm{T}(spzeros(T, 0)),
        SparseQuadraticForm{T}(spzeros(T, 0, 0)),
        scale,
        offset;
        sense,
        domain,
    )

    return Model{V,T,U}(
        variables_map,
        form;
        metadata,
        solution,
        start,
        id,
        description,
    )
end

# Dict Constructors
function Model(
    linear_terms::Dict{V,T},
    quadratic_terms::Dict{Tuple{V,V},T};
    kws...,
) where {V,T}
    return Model{V,T,Int}(linear_terms, quadratic_terms; kws...)
end

function Model{V,T,U}(
    linear_terms::Dict{V,T},
    quadratic_terms::Dict{Tuple{V,V},T};
    scale::T = one(T),
    offset::T = zero(T),
    kws...,
) where {V,T,U}
    # Collect Variables
    variable_set = Set{V}(keys(linear_terms))

    for (i, j) in keys(quadratic_terms)
        push!(variable_set, i, j)
    end

    return Model{V,T,U}(variable_set, linear_terms, quadratic_terms; scale, offset, kws...)
end

function Model{V,T,U}(
    variable_set::Set{V},
    linear_terms::Dict{V,T},
    quadratic_terms::Dict{Tuple{V,V},T};
    scale::T                     = one(T),
    offset::T                    = zero(T),
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
    kws...,
) where {V,T,U}
    variable_map = VariableMap{V}(variable_set)

    # Normalize data and store it in the normal form
    n = length(variable_set)
    L = spzeros(T, n)
    Q = spzeros(T, n, n)
    α = scale
    β = offset

    for (v, l) in linear_terms
        i = variable_map.map[v]

        L[i] += l
    end

    for ((u, v), q) in quadratic_terms
        i = variable_map.map[u]
        j = variable_map.map[v]

        if i < j
            Q[i, j] += q
        elseif j < i
            Q[j, i] += q
        else # i == j
            L[i] += q
        end
    end

    dropzeros!(L)
    dropzeros!(Q)

    form = Form{T}(
        n,
        SparseLinearForm{T}(L),
        SparseQuadraticForm{T}(Q),
        α,
        β;
        sense,
        domain,
    )

    return Model{V,T,U}(variable_map, form; kws...)
end

form(model::Model) = model.form

dimension(model::Model) = dimension(form(model))

function index(model::Model{V}, v::V) where {V}
    if hasvariable(model, v)
        return index(model.variable_map, v)
    else
        error("Variable '$v' does not belong to the model")

        return nothing
    end
end

variables(model::Model) = model.variable_map.inv

function hasvariable(model::Model{V}, v::V) where {V}
    return haskey(model.variable_map.map, v)
end

linear_terms(model::Model)    = linear_terms(form(model))
quadratic_terms(model::Model) = quadratic_terms(form(model))

scale(model::Model)  = scale(form(model))
offset(model::Model) = offset(form(model))

frame(model::Model) = frame(form(model))

metadata(model::Model) = model.metadata
solution(model::Model) = model.solution

function start(model::Model{V,T,U}, i::Integer; domain = QUBOTools.domain(model)) where {V,T,U}
    if !hasindex(model, i)
        error("Index '$i' is out of bounds [1, $(dimension(model))]")

        return nothing
    elseif haskey(model.start, i)
        return cast((QUBOTools.domain(model) => domain), model.start[i])
    else
        return nothing
    end 
end

function start(model::Model{V,T,U}; domain = QUBOTools.domain(model)) where {V,T,U}
    return Dict{Int,U}(i => start(model, i; domain) for i in keys(model.start))
end

function Base.empty!(model::Model{V,T,U,F}) where {V,T,U,F}
    model.form         = F()
    model.variable_map = VariableMap{V}(V[])
    model.solution     = SampleSet{T,U}()

    empty!(model.metadata)
    empty!(model.start)

    return model
end

function Base.copy(model::Model{V,T,U,F}) where {V,T,U,F}
    return copy!(Model{V,T,U,F}(), model)
end

function Base.copy!(target::Model{V}, source::AbstractModel{V}) where {V}
    target.form      = copy(form(source))
    target.variables = VariableMap{V}(variables(source))
    target.metadata  = deepcopy(metadata(source))
    target.solution  = copy(solution(source))
    target.start     = deepcopy(start(source))

    return target
end

function cast(route::Route{D}, model::Model{V,T,U}) where {D<:Domain,V,T,U}
    return Model{V,T,U}(
        cast(route, form(model)),
        model.variable_map;
        metadata = deepcopy(metadata(model)),
        solution = cast(route, solution(model)),
        start    = start(model; domain = last(route)),
    )
end

function cast(route::Route{S}, model::Model{V,T,U}) where {S<:Sense,V,T,U}
    return Model{V,T,U}(
        cast(route, form(model)),
        model.variable_map;
        metadata = deepcopy(metadata(model)),
        solution = cast(route, solution(model)),
        start    = deepcopy(start(model)),
    )
end

function attach!(model::Model{V,T,U}, sol::SampleSet{T,U}) where {V,T,U}
    model.solution = cast((frame(sol) => frame(model)), sol)

    return model.solution
end

function attach!(model::Model{V,T,U}, (v,s)::Pair{V,U}) where {V,T,U}
    i = index(model, v)

    model.start[i] = s

    return (i, s)
end

function attach!(model::Model{V,T,U}, sol::Dict{V,U}) where {V,T,U}
    # This operation is meant to be atomic, i.e., when attaching a warm-start
    # dict to the model, if the operation fails during variable mapping, the
    # original dict is left unchanged. This is why the attach!(model, v => s)
    # method is not used here.
    cache = sizehint!(Dict{Int,U}(), length(sol))

    for (v, s) in sol
        i = index(model, v)

        cache[i] = s
    end

    copy!(model.start, cache)

    return model.start
end

function Model{V,T,U}(f::F; kws...) where {V,T,U,F<:PBO.AbstractFunction{V,T}}
    L = Dict{V,T}()
    Q = Dict{Tuple{V,V},T}()
    β = zero(T)

    for (ω, c) in f
        if length(ω) == 0
            β += c
        elseif length(ω) == 1
            i, = ω

            L[i] = get(L, i, zero(T)) + c
        elseif length(ω) == 2
            i, j = ω

            Q[(i, j)] = get(Q, (i, j), zero(T)) + c
        else
            throw(
                DomainError(
                    length(ω),
                    """
                    Can't create QUBO model from a high-order pseudo-Boolean function.
                    Consider using `PseudoBooleanOptimization.quadratize`.
                    """
                )
            )
        end
    end

    return Model{V,T,U}(L, Q; offset = β, sense = :min, domain = :bool, kws...)
end
