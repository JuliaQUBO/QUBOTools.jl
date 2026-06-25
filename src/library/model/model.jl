@doc raw"""
    Model{V,T,U,F<:AbstractForm{T}} <: AbstractModel{V,T,U}

Reference [`AbstractModel`](@ref) implementation.
It is intended to be the stardard in-memory representation for QUBO models.

## Sparse Constructors

```julia
Model{V,T,U}(variables, L::SparseVector, Q::SparseMatrixCSC; kws...)
Model{V,T,U}(
    variables,
    linear_indices,
    linear_values,
    quadratic_rows,
    quadratic_cols,
    quadratic_values;
    kws...,
)
```

These constructors build the model's sparse normal form directly. The vector
`variables` defines the public variable-index mapping: `variables[i]` maps to
index `i`, and all variables must be unique. COO indices are 1-based positions
in that vector. Unlike dictionary and set constructors, which sort variables
with `varlt`, sparse constructors preserve the caller-supplied variable order.

Quadratic inputs are normalized to strict upper-triangular storage. Entries with
`i > j` are stored as `(j, i)`, diagonal entries are accumulated into the linear
form, duplicate coordinates are summed by Julia's sparse constructors, and
resulting explicit zeros are removed with `dropzeros!`. Pass upper-triangular
quadratic data, or pre-halve mirrored off-diagonal entries; a full symmetric
matrix contributes both `(i, j)` and `(j, i)` and therefore doubles each
off-diagonal coefficient in the stored normal form.

`scale` and `offset` are stored as the model's normal-form scale and offset; the
coefficient inputs are not pre-scaled. Objective evaluation uses
`scale * (linear + quadratic + offset)`.

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

    # Direct Constructor
    function Model{V,T,U,F}(
        variable_map::VariableMap{V},
        form::F,
        metadata::Dict{String,Any},
        solution::SampleSet{T,U},
        start::Dict{Int,U},
    ) where {V,T,U,F<:AbstractForm{T}}
        return new{V,T,U,F}(variable_map, form, metadata, solution, start)
    end
end

# Internal helper for efficient sparse-form construction from variable dictionaries.
function _build_sparse_forms(
    variable_map::VariableMap{V},
    linear_terms::Dict{V,T},
    quadratic_terms::Dict{Tuple{V,V},T},
) where {V,T}
    n = length(variable_map)
    map = variable_map.map

    linear_indices = Int[]
    linear_values = T[]
    sizehint!(linear_indices, length(linear_terms) + length(quadratic_terms))
    sizehint!(linear_values, length(linear_terms) + length(quadratic_terms))

    for (v, l) in linear_terms
        push!(linear_indices, map[v])
        push!(linear_values, l)
    end

    quadratic_rows = Int[]
    quadratic_cols = Int[]
    quadratic_values = T[]
    sizehint!(quadratic_rows, length(quadratic_terms))
    sizehint!(quadratic_cols, length(quadratic_terms))
    sizehint!(quadratic_values, length(quadratic_terms))

    for ((u, v), q) in quadratic_terms
        i = map[u]
        j = map[v]

        if i < j
            push!(quadratic_rows, i)
            push!(quadratic_cols, j)
            push!(quadratic_values, q)
        elseif j < i
            push!(quadratic_rows, j)
            push!(quadratic_cols, i)
            push!(quadratic_values, q)
        else # i == j
            push!(linear_indices, i)
            push!(linear_values, q)
        end
    end

    L = sparsevec(linear_indices, linear_values, n)
    Q = sparse(quadratic_rows, quadratic_cols, quadratic_values, n, n)

    dropzeros!(L)
    dropzeros!(Q)

    return L, Q
end

function _variable_map_from_indices(variables::AbstractVector{V}) where {V}
    inv = collect(variables)
    map = sizehint!(Dict{V,Int}(), length(inv))

    for (i, v) in enumerate(inv)
        if haskey(map, v)
            throw(ArgumentError("variables must be unique; duplicate variable '$v'"))
        end

        map[v] = i
    end

    return VariableMap{V}(map, inv)
end

function _check_sparse_index(i::Integer, n::Integer, name::String)
    if !(1 <= i <= n)
        throw(ArgumentError("$name index $i is out of range 1:$n"))
    end

    return Int(i)
end

function _build_sparse_forms(
    ::Type{T},
    n::Integer,
    linear_indices::AbstractVector{<:Integer},
    linear_values::AbstractVector,
    quadratic_rows::AbstractVector{<:Integer},
    quadratic_cols::AbstractVector{<:Integer},
    quadratic_values::AbstractVector,
) where {T}
    length(linear_indices) == length(linear_values) ||
        throw(DimensionMismatch("linear_indices and linear_values must have the same length"))
    length(quadratic_rows) == length(quadratic_cols) == length(quadratic_values) || throw(
        DimensionMismatch(
            "quadratic_rows, quadratic_cols, and quadratic_values must have the same length",
        ),
    )

    n = Int(n)

    linear_i = Int[]
    linear_v = T[]
    sizehint!(linear_i, length(linear_values) + length(quadratic_values))
    sizehint!(linear_v, length(linear_values) + length(quadratic_values))

    for (i, v) in zip(linear_indices, linear_values)
        push!(linear_i, _check_sparse_index(i, n, "linear"))
        push!(linear_v, convert(T, v))
    end

    quadratic_i = Int[]
    quadratic_j = Int[]
    quadratic_v = T[]
    sizehint!(quadratic_i, length(quadratic_values))
    sizehint!(quadratic_j, length(quadratic_values))
    sizehint!(quadratic_v, length(quadratic_values))

    for (row, col, val) in zip(quadratic_rows, quadratic_cols, quadratic_values)
        i = _check_sparse_index(row, n, "quadratic row")
        j = _check_sparse_index(col, n, "quadratic column")
        v = convert(T, val)

        if i < j
            push!(quadratic_i, i)
            push!(quadratic_j, j)
            push!(quadratic_v, v)
        elseif j < i
            push!(quadratic_i, j)
            push!(quadratic_j, i)
            push!(quadratic_v, v)
        else # i == j
            push!(linear_i, i)
            push!(linear_v, v)
        end
    end

    L = sparsevec(linear_i, linear_v, n)
    Q = sparse(quadratic_i, quadratic_j, quadratic_v, n, n)

    dropzeros!(L)
    dropzeros!(Q)

    return L, Q
end

function _build_sparse_forms(
    ::Type{T},
    n::Integer,
    L::SparseVector,
    Q::SparseMatrixCSC,
) where {T}
    n = Int(n)

    length(L) == n || throw(
        DimensionMismatch("linear sparse vector length $(length(L)) does not match $n variables"),
    )
    size(Q) == (n, n) || throw(
        DimensionMismatch("quadratic sparse matrix size $(size(Q)) does not match ($n, $n)"),
    )

    linear_indices, linear_values = findnz(L)
    quadratic_rows, quadratic_cols, quadratic_values = findnz(Q)

    return _build_sparse_forms(
        T,
        n,
        linear_indices,
        linear_values,
        quadratic_rows,
        quadratic_cols,
        quadratic_values,
    )
end

# Canonical Constructor - Normal Form
function Model{V,T,U}(
    variable_map::VariableMap{V},
    form::F;
    metadata::Union{Dict{String,Any},Nothing} = nothing,
    solution::Union{SampleSet{T,U},Nothing} = nothing,
    start::Union{Dict{V,U},Nothing} = nothing,
    # Extra Metadata
    id::Union{Integer,Nothing} = nothing,
    description::Union{String,Nothing} = nothing,
) where {V,T,U,F<:AbstractForm{T}}
    if isnothing(metadata)
        metadata = Dict{String,Any}()
    end

    if !isnothing(id)
        metadata["id"] = id
    end

    if !isnothing(description)
        metadata["description"] = description
    end

    model = Model{V,T,U,F}(variable_map, form, metadata, SampleSet{T,U}(), Dict{Int,U}())

    if !isnothing(solution)
        attach!(model, solution)
    end

    if !isnothing(start)
        attach!(model, start)
    end

    return model
end

# Empty Constructor
function Model{V,T,U}(;
    scale::T = one(T),
    offset::T = zero(T),
    sense::Union{Sense,Symbol} = :min,
    domain::Union{Domain,Symbol} = :bool,
    metadata::Union{Dict{String,Any},Nothing} = nothing,
    solution::Union{SampleSet{T,U},Nothing} = nothing,
    start::Union{Dict{V,U},Nothing} = nothing,
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

    return Model{V,T,U}(variables_map, form; metadata, solution, start, id, description)
end

# Sparse Constructors
function Model(
    variables::AbstractVector{V},
    L::SparseVector{LT},
    Q::SparseMatrixCSC{QT};
    kws...,
) where {V,LT,QT}
    return Model{V,promote_type(LT,QT),Int}(variables, L, Q; kws...)
end

function Model{V,T,U}(
    variables::AbstractVector{V},
    L::SparseVector,
    Q::SparseMatrixCSC;
    scale::T                     = one(T),
    offset::T                    = zero(T),
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
    kws...,
) where {V,T,U}
    variable_map = _variable_map_from_indices(variables)
    n = length(variable_map)
    L, Q = _build_sparse_forms(T, n, L, Q)

    form =
        Form{T}(n, SparseLinearForm{T}(L), SparseQuadraticForm{T}(Q), scale, offset; sense, domain)

    return Model{V,T,U}(variable_map, form; kws...)
end

function Model(
    variables::AbstractVector{V},
    linear_indices::AbstractVector{<:Integer},
    linear_values::AbstractVector{LT},
    quadratic_rows::AbstractVector{<:Integer},
    quadratic_cols::AbstractVector{<:Integer},
    quadratic_values::AbstractVector{QT};
    kws...,
) where {V,LT,QT}
    return Model{V,promote_type(LT,QT),Int}(
        variables,
        linear_indices,
        linear_values,
        quadratic_rows,
        quadratic_cols,
        quadratic_values;
        kws...,
    )
end

function Model{V,T,U}(
    variables::AbstractVector{V},
    linear_indices::AbstractVector{<:Integer},
    linear_values::AbstractVector,
    quadratic_rows::AbstractVector{<:Integer},
    quadratic_cols::AbstractVector{<:Integer},
    quadratic_values::AbstractVector;
    scale::T                     = one(T),
    offset::T                    = zero(T),
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
    kws...,
) where {V,T,U}
    variable_map = _variable_map_from_indices(variables)
    n = length(variable_map)
    L, Q = _build_sparse_forms(
        T,
        n,
        linear_indices,
        linear_values,
        quadratic_rows,
        quadratic_cols,
        quadratic_values,
    )

    form =
        Form{T}(n, SparseLinearForm{T}(L), SparseQuadraticForm{T}(Q), scale, offset; sense, domain)

    return Model{V,T,U}(variable_map, form; kws...)
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
    L, Q = _build_sparse_forms(variable_map, linear_terms, quadratic_terms)
    α = scale
    β = offset

    form =
        Form{T}(n, SparseLinearForm{T}(L), SparseQuadraticForm{T}(Q), α, β; sense, domain)

    return Model{V,T,U}(variable_map, form; kws...)
end

form(model::Model) = model.form

dimension(model::Model) = dimension(form(model))

function index(model::Model{V}, v::V) where {V}
    if hasvariable(model, v)
        return index(model.variable_map, v)
    else
        error("Variable '$v' does not belong to the model")
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

function start(
    model::Model{V,T,U},
    i::Integer;
    domain = QUBOTools.domain(model),
) where {V,T,U}
    if !hasindex(model, i)
        error("Index '$i' is out of bounds [1, $(dimension(model))]")
    elseif haskey(model.start, i)
        return cast((QUBOTools.domain(model) => QUBOTools.domain(domain)), model.start[i])
    else
        return nothing
    end
end

function start(model::Model{V,T,U}; domain = QUBOTools.domain(model)) where {V,T,U}
    return Dict{Int,U}(i => start(model, i; domain) for i in keys(model.start))
end

function Base.empty!(model::Model{V,T,U,F}) where {V,T,U,F}
    model.variable_map = VariableMap{V}(V[])

    null_form = Form{T}(
        0,
        SparseLinearForm{T}(spzeros(T, 0)),
        SparseQuadraticForm{T}(spzeros(T, 0, 0)),
        zero(T),
        zero(T),
    )

    model.form     = F(null_form)
    model.solution = SampleSet{T,U}()

    empty!(model.metadata)
    empty!(model.start)

    return model
end

function Base.copy(model::Model{V,T,U,F}) where {V,T,U,F}
    return Model{V,T,U,F}(
        copy(model.variable_map),
        copy(model.form),
        deepcopy(model.metadata),
        copy(model.solution),
        copy(model.start),
    )
end

function Base.copy!(target::Model{V}, source::AbstractModel{V}) where {V}
    target.variable_map = copy(source.variable_map)
    target.form         = copy(source.form)
    target.metadata     = deepcopy(source.metadata)
    target.solution     = copy(source.solution)
    target.start        = copy(source.start)

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

function attach!(model::Model{V,T,U}, (v, s)::Pair{V,S}) where {V,T,U,S<:Union{U,Nothing}}
    i = index(model, v)

    if !isnothing(s)
        model.start[i] = s
    else
        delete!(model.start, i)
    end

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
                    It is not possible to create a QUBO model from a high-order pseudo-Boolean function.
                    Consider using `PseudoBooleanOptimization.quadratize`.
                    """,
                ),
            )
        end
    end

    return Model{V,T,U}(L, Q; offset = β, sense = :min, domain = :bool, kws...)
end

function map_variables(::Type{V}, vm::Function, model::Model{_,T,U,F}) where {_,V,T,U,F}
    new_model = copy(model)::Model{V,T,U,F}
    new_model.variable_map = VariableMap{V}(Dict{Int,V}(i => vm(i)::V for i in indices(model)))

    return new_model
end

map_variables(vm::Dict{Int,V}, model::AbstractModel) where {V}       = map_variables(V, i -> vm[i], model)
map_variables(vm::AbstractVector{V}, model::AbstractModel) where {V} = map_variables(V, i -> vm[i], model)
