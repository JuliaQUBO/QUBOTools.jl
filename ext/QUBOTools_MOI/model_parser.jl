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

    V = Set{VI}(MOI.get(model, MOI.ListOfVariableIndices()))
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
            return _extract_bool_model(T, model, V, fixed)
        end
    else # isempty(𝔹) # Ising model?
        if 𝕊 != V
            qubo_parsing_error("Not all variables in the given model are spin.\n")
        else
            return _extract_spin_model(T, model, V, fixed)
        end
    end
end

function _extract_bool_model(::Type{T}, model::MOI.ModelLike, V::Set{VI}, fixed::Dict{VI,T}) where {T}
    L = Dict{VI,T}(xi => zero(T) for xi ∈ V if !haskey(fixed, xi))
    Q = Dict{Tuple{VI,VI},T}()

    β = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        if haskey(fixed, f)
            β += fixed[f]
        else
            L[f] += one(T)
        end
    elseif F <: SAF
        for a in f.terms
            ci = a.coefficient
            xi = a.variable

            if haskey(fixed, xi)
                β += fixed[xi] * ci
            else
                L[xi] += ci
            end
        end

        β += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            ci = a.coefficient
            xi = a.variable

            if haskey(fixed, xi)
                β += fixed[xi] * ci
            else
                L[xi] += ci
            end
        end

        for a in f.quadratic_terms
            cij = a.coefficient
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
                    L[xi] += cij / 2
                end
            elseif haskey(fixed, xi) && haskey(fixed, xj)
                β += fixed[xi] * fixed[xj] * cij
            elseif haskey(fixed, xi)
                L[xj] += fixed[xi] * cij
            elseif haskey(fixed, xj)
                L[xi] += fixed[xj] * cij
            else
                Q[(xi, xj)] = get(Q, (xi, xj), zero(T)) + cij
            end
        end

        β += f.constant
    end

    return QUBOTools.Model{VI,T,Int}(
        L,
        Q;
        offset = β,
        sense  = QUBOTools.sense(MOI.get(model, MOI.ObjectiveSense())),
        domain = :bool,
    )
end

function _extract_spin_model(::Type{T}, model::MOI.ModelLike, V::Set{VI}, fixed::Dict{VI,T}) where {T}
    L = Dict{VI,T}(xi => zero(T) for xi ∈ V if !haskey(fixed, xi))
    Q = Dict{Tuple{VI,VI},T}()

    β = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        if haskey(fixed, f)
            β += fixed[f]
        else
            L[f] += one(T)
        end
    elseif F <: SAF
        for a in f.terms
            ci = a.coefficient
            xi = a.variable

            if haskey(fixed, xi)
                β += fixed[xi] * ci
            else
                L[xi] += ci
            end
        end

        β += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            ci = a.coefficient
            xi = a.variable

            if haskey(fixed, xi)
                β += fixed[xi] * ci
            else
                L[xi] += ci
            end
        end

        for a in f.quadratic_terms
            cij = a.coefficient
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
                L[xj] += fixed[xi] * cij
            elseif haskey(fixed, xj)
                L[xi] += fixed[xj] * cij
            else
                Q[(xi, xj)] = get(Q, (xi, xj), zero(T)) + cij
            end
        end

        β += f.constant
    end

    return QUBOTools.Model{VI,T,Int}(
        L,
        Q;
        offset = β,
        sense  = QUBOTools.sense(MOI.get(model, MOI.ObjectiveSense())),
        domain = :spin,
    )
end
