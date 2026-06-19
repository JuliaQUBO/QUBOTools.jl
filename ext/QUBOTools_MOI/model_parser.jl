function QUBOTools.Model(model::MOI.ModelLike)
    return QUBOTools.Model{Float64}(model)
end

function QUBOTools.Model{T}(model::MOI.ModelLike) where {T}
    return _parse_moi_model(T, model)
end

_fixed_set_type(type::Type{MOI.EqualTo{T}}) where {T} = type

function _model_info(model::MOI.ModelLike)
    info = Dict{Symbol,Any}(
        :has_sense      => false,
        :is_quadratic   => false,
        :is_constrained => false,
        :is_fixed       => false,
        :var_type       => nothing,
        :fixed_set_type => nothing,
    )

    let s = MOI.get(model, MOI.ObjectiveSense())
        info[:has_sense] = (s === MOI.MAX_SENSE || s === MOI.MIN_SENSE)
    end

    let F = MOI.get(model, MOI.ObjectiveFunctionType())
        info[:is_quadratic] = (F <: SQF || F <: SAF || F <: VI)
    end

    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if F === VI
            if S ∈ (MOI.ZeroOne, Spin)
                if !isnothing(info[:var_type]) && info[:var_type] !== S
                    qubo_parsing_error("Variables have to be either all boolean or all spin.")
                else
                    info[:var_type] = S
                end

                continue
            elseif (S <: MOI.EqualTo)
                info[:is_fixed]       = true
                info[:fixed_set_type] = _fixed_set_type(S)

                continue
            end
        end

        info[:is_constrained] = true
    end

    return info
end

function _parse_moi_model(::Type{T}, model::MOI.ModelLike) where {T}
    if MOI.is_empty(model)
        return QUBOTools.Model{VI,T,Int}(; sense  = :min, domain = :bool)
    end

    info = _model_info(model)

    if isnothing(info[:var_type])
        qubo_parsing_error("Variables have to be either boolean or spin")
    end

    if !info[:has_sense]
        qubo_parsing_error("""
                           The provided model has an invalid optimization sense.
                           It should be either minimization or maximization.
                           """)

        return nothing
    end

    if !info[:is_quadratic]
        qubo_parsing_error(
            "The provided model's objective function is not a quadratic polynomial.\n",
        )

        return nothing
    end

    if info[:is_constrained]
        qubo_parsing_error("The provided model is not unconstrained.\n")
    end

    variables = MOI.get(model, MOI.ListOfVariableIndices())
    V = Set{VI}(variables)
    𝔹 = Set{VI}()
    𝕊 = Set{VI}()

    fixed = Dict{VI,T}()

    if MOI.supports_constraint(model, VI, MOI.ZeroOne)
        for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.ZeroOne}())
            vi = MOI.get(model, MOI.ConstraintFunction(), ci)

            push!(𝔹, vi)
        end
    end

    if MOI.supports_constraint(model, VI, Spin)
        for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,Spin}())
            vi = MOI.get(model, MOI.ConstraintFunction(), ci)
            
            (vi ∈ 𝕊) && qubo_parsing_error("A variable can not be boolean and spin at the same time.\n")

            push!(𝕊, vi)
        end
    end

    if info[:is_fixed]
        let FST = info[:fixed_set_type]
            for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,FST}())
                vi = MOI.get(model, MOI.ConstraintFunction(), ci)
                si = MOI.get(model, MOI.ConstraintSet(), ci)

                fixed[vi] = convert(T, si.value)
                    
                if vi ∈ 𝔹
                    @assert fixed[vi] == zero(T) || fixed[vi] == one(T)
                else # vi ∈ 𝕊
                    @assert fixed[vi] == -one(T) || fixed[vi] == one(T)
                end
            end
        end
    end

    # Retrieve Variable Domain
    # Assuming: 𝕊, 𝔹 ⊆ V
    if !isempty(𝕊) && !isempty(𝔹)
        qubo_parsing_error("The given model contains both boolean and spin variables.\n")
    elseif isempty(𝕊) # QUBO model?
        if 𝔹 != V
            qubo_parsing_error("Not all variables in the given model are boolean.\n")
        else
            return _extract_bool_model(T, model, variables, fixed)
        end
    else # isempty(𝔹) # Ising model?
        if 𝕊 != V
            qubo_parsing_error("Not all variables in the given model are spin.\n")
        else
            return _extract_spin_model(T, model, variables, fixed)
        end
    end
end

function _remaining_variable_map(variables::AbstractVector{VI}, fixed::Dict{VI,T}) where {T}
    if isempty(fixed)
        return QUBOTools.VariableMap{VI}(variables)
    else
        return QUBOTools.VariableMap{VI}(VI[xi for xi in variables if !haskey(fixed, xi)])
    end
end

# Avoid huge lookup vectors for MOI backends with sparse variable ids.
const _DENSE_VARIABLE_LOOKUP_MAX_FACTOR = 4

function _variable_index_lookup(variable_map::QUBOTools.VariableMap{VI})
    n = length(variable_map)

    iszero(n) && return Int[]

    max_value = 0

    for vi in variable_map.inv
        value = vi.value

        value > 0 || return variable_map.map

        max_value = max(max_value, value)
    end

    max_value <= _DENSE_VARIABLE_LOOKUP_MAX_FACTOR * n || return variable_map.map

    lookup = zeros(Int, max_value)

    for (i, vi) in enumerate(variable_map.inv)
        @inbounds lookup[vi.value] = i
    end

    return lookup
end

@inline function _variable_index(variable_index::Dict{VI,Int}, xi::VI)
    return variable_index[xi]
end

@inline function _variable_index(variable_index::Vector{Int}, xi::VI)
    value = xi.value

    if !(1 <= value <= length(variable_index))
        throw(KeyError(xi))
    end

    i = @inbounds variable_index[value]

    if iszero(i)
        throw(KeyError(xi))
    end

    return i
end

function _append_linear_term!(
    linear_indices::Vector{Int},
    linear_values::Vector{T},
    variable_index,
    xi::VI,
    ci,
) where {T}
    push!(linear_indices, _variable_index(variable_index, xi))
    push!(linear_values, ci)

    return nothing
end

function _append_quadratic_term!(
    quadratic_rows::Vector{Int},
    quadratic_cols::Vector{Int},
    quadratic_values::Vector{T},
    variable_index,
    xi::VI,
    xj::VI,
    cij,
) where {T}
    i = _variable_index(variable_index, xi)
    j = _variable_index(variable_index, xj)

    if i < j
        push!(quadratic_rows, i)
        push!(quadratic_cols, j)
    else
        push!(quadratic_rows, j)
        push!(quadratic_cols, i)
    end

    push!(quadratic_values, cij)

    return nothing
end

function _add_linear_or_offset!(
    linear_indices::Vector{Int},
    linear_values::Vector{T},
    variable_index,
    fixed::Dict{VI,T},
    β::T,
    xi::VI,
    ci,
) where {T}
    if haskey(fixed, xi)
        return β + fixed[xi] * ci
    else
        _append_linear_term!(linear_indices, linear_values, variable_index, xi, ci)

        return β
    end
end

function _finalize_moi_model(
    ::Type{T},
    variable_map::QUBOTools.VariableMap{VI},
    linear_indices::Vector{Int},
    linear_values::Vector{T},
    quadratic_rows::Vector{Int},
    quadratic_cols::Vector{Int},
    quadratic_values::Vector{T},
    β::T;
    sense::QUBOTools.Sense,
    domain::Symbol,
) where {T}
    n = length(variable_map)

    L = sparsevec(linear_indices, linear_values, n)
    Q = sparse(quadratic_rows, quadratic_cols, quadratic_values, n, n)

    dropzeros!(L)
    dropzeros!(Q)

    form = QUBOTools.Form{T}(
        n,
        QUBOTools.SparseLinearForm{T}(L),
        QUBOTools.SparseQuadraticForm{T}(Q),
        one(T),
        β;
        sense,
        domain,
    )

    return QUBOTools.Model{VI,T,Int}(variable_map, form)
end

function _extract_bool_model(
    ::Type{T},
    model::MOI.ModelLike,
    variables::AbstractVector{VI},
    fixed::Dict{VI,T},
) where {T}
    variable_map = _remaining_variable_map(variables, fixed)
    variable_index = _variable_index_lookup(variable_map)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    affine_count = F <: SQF ? length(f.affine_terms) : F <: SAF ? length(f.terms) : 1
    quadratic_count = F <: SQF ? length(f.quadratic_terms) : 0

    linear_indices = Int[]
    linear_values = T[]
    sizehint!(linear_indices, affine_count + quadratic_count)
    sizehint!(linear_values, affine_count + quadratic_count)

    quadratic_rows = Int[]
    quadratic_cols = Int[]
    quadratic_values = T[]
    sizehint!(quadratic_rows, quadratic_count)
    sizehint!(quadratic_cols, quadratic_count)
    sizehint!(quadratic_values, quadratic_count)

    β = zero(T)

    if F <: VI
        ci = one(T)

        if haskey(fixed, f)
            β += fixed[f] * ci
        else
            _append_linear_term!(linear_indices, linear_values, variable_index, f, ci)
        end
    elseif F <: SAF
        for a in f.terms
            ci = convert(T, a.coefficient)
            xi = a.variable

            β = _add_linear_or_offset!(
                linear_indices,
                linear_values,
                variable_index,
                fixed,
                β,
                xi,
                ci,
            )
        end

        β += convert(T, f.constant)
    elseif F <: SQF
        for a in f.affine_terms
            ci = convert(T, a.coefficient)
            xi = a.variable

            β = _add_linear_or_offset!(
                linear_indices,
                linear_values,
                variable_index,
                fixed,
                β,
                xi,
                ci,
            )
        end

        for a in f.quadratic_terms
            cij = convert(T, a.coefficient)
            xi = a.variable_1
            xj = a.variable_2

            if xi == xj
                # ~ MOI assumes 
                #       SQF := ½ x' Q x + a' x + β
                #   Thus, the main diagonal is doubled from our point of view
                # ~ Also, in this case, x² = x
                if haskey(fixed, xi)
                    β += fixed[xi] * cij / 2
                else
                    _append_linear_term!(
                        linear_indices,
                        linear_values,
                        variable_index,
                        xi,
                        cij / 2,
                    )
                end
            elseif haskey(fixed, xi) && haskey(fixed, xj)
                β += fixed[xi] * fixed[xj] * cij
            elseif haskey(fixed, xi)
                _append_linear_term!(
                    linear_indices,
                    linear_values,
                    variable_index,
                    xj,
                    fixed[xi] * cij,
                )
            elseif haskey(fixed, xj)
                _append_linear_term!(
                    linear_indices,
                    linear_values,
                    variable_index,
                    xi,
                    fixed[xj] * cij,
                )
            else
                _append_quadratic_term!(
                    quadratic_rows,
                    quadratic_cols,
                    quadratic_values,
                    variable_index,
                    xi,
                    xj,
                    cij,
                )
            end
        end

        β += convert(T, f.constant)
    end

    return _finalize_moi_model(
        T,
        variable_map,
        linear_indices,
        linear_values,
        quadratic_rows,
        quadratic_cols,
        quadratic_values,
        β;
        sense = QUBOTools.sense(MOI.get(model, MOI.ObjectiveSense())),
        domain = :bool,
    )
end

function _extract_spin_model(
    ::Type{T},
    model::MOI.ModelLike,
    variables::AbstractVector{VI},
    fixed::Dict{VI,T},
) where {T}
    variable_map = _remaining_variable_map(variables, fixed)
    variable_index = _variable_index_lookup(variable_map)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    affine_count = F <: SQF ? length(f.affine_terms) : F <: SAF ? length(f.terms) : 1
    quadratic_count = F <: SQF ? length(f.quadratic_terms) : 0

    linear_indices = Int[]
    linear_values = T[]
    sizehint!(linear_indices, affine_count + quadratic_count)
    sizehint!(linear_values, affine_count + quadratic_count)

    quadratic_rows = Int[]
    quadratic_cols = Int[]
    quadratic_values = T[]
    sizehint!(quadratic_rows, quadratic_count)
    sizehint!(quadratic_cols, quadratic_count)
    sizehint!(quadratic_values, quadratic_count)

    β = zero(T)

    if F <: VI
        ci = one(T)

        if haskey(fixed, f)
            β += fixed[f] * ci
        else
            _append_linear_term!(linear_indices, linear_values, variable_index, f, ci)
        end
    elseif F <: SAF
        for a in f.terms
            ci = convert(T, a.coefficient)
            xi = a.variable

            β = _add_linear_or_offset!(
                linear_indices,
                linear_values,
                variable_index,
                fixed,
                β,
                xi,
                ci,
            )
        end

        β += convert(T, f.constant)
    elseif F <: SQF
        for a in f.affine_terms
            ci = convert(T, a.coefficient)
            xi = a.variable

            β = _add_linear_or_offset!(
                linear_indices,
                linear_values,
                variable_index,
                fixed,
                β,
                xi,
                ci,
            )
        end

        for a in f.quadratic_terms
            cij = convert(T, a.coefficient)
            xi = a.variable_1
            xj = a.variable_2

            if xi == xj
                # ~ MOI assumes 
                #       SQF := ½ s' J s + h' s + β
                #   Thus, the main diagonal is doubled from our point of view
                # ~ Also, in this case, s² = 1
                β += cij / 2
            elseif haskey(fixed, xi) && haskey(fixed, xj)
                β += fixed[xi] * fixed[xj] * cij
            elseif haskey(fixed, xi)
                _append_linear_term!(
                    linear_indices,
                    linear_values,
                    variable_index,
                    xj,
                    fixed[xi] * cij,
                )
            elseif haskey(fixed, xj)
                _append_linear_term!(
                    linear_indices,
                    linear_values,
                    variable_index,
                    xi,
                    fixed[xj] * cij,
                )
            else
                _append_quadratic_term!(
                    quadratic_rows,
                    quadratic_cols,
                    quadratic_values,
                    variable_index,
                    xi,
                    xj,
                    cij,
                )
            end
        end

        β += convert(T, f.constant)
    end

    return _finalize_moi_model(
        T,
        variable_map,
        linear_indices,
        linear_values,
        quadratic_rows,
        quadratic_cols,
        quadratic_values,
        β;
        sense = QUBOTools.sense(MOI.get(model, MOI.ObjectiveSense())),
        domain = :spin,
    )
end
