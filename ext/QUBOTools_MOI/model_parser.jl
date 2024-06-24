function QUBOTools.Model(model::MOI.ModelLike)
    return QUBOTools.Model{Float64}(model)
end

function QUBOTools.Model{T}(model::MOI.ModelLike) where {T}
    return _parse_moi_model(T, model)
end


function _is_optimization(model::MOI.ModelLike)
    S = MOI.get(model, MOI.ObjectiveSense())

    return (S === MOI.MAX_SENSE || S === MOI.MIN_SENSE)
end

function _is_quadratic(model::MOI.ModelLike)
    return MOI.get(model, MOI.ObjectiveFunctionType()) <: Union{SQF,SAF,VI}
end

function _is_unconstrained(model::MOI.ModelLike)
    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if !(F === VI && (S === MOI.ZeroOne || S === Spin))
            return false
        end
    end

    return true
end


function _parse_moi_model(::Type{T}, model::MOI.ModelLike) where {T}
    if MOI.is_empty(model)
        return QUBOTools.Model{VI,T,Int}(;
            sense  = :min,
            domain = :bool,
        )
    end

    if !_is_optimization(model)
        qubo_parsing_error("""
                           The provided model has an invalid optimization sense.
                           It should be either minimization or maximization.
                           """)

        return nothing
    end

    if !_is_quadratic(model)
        qubo_parsing_error("The provided model's objective function is not a quadratic polynomial.\n")

        return nothing
    end

    if !_is_unconstrained(model)
        qubo_parsing_error("The provided model is not unconstrained.\n")
    end

    Ω = Set{VI}(MOI.get(model, MOI.ListOfVariableIndices()))
    𝔹 = Set{VI}()
    𝕊 = Set{VI}()

    if MOI.supports_constraint(model, VI, MOI.ZeroOne)
        for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.ZeroOne}())
            push!(𝔹, MOI.get(model, MOI.ConstraintFunction(), ci))
        end
    end

    if MOI.supports_constraint(model, VI, Spin)
        for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,Spin}())
            push!(𝕊, MOI.get(model, MOI.ConstraintFunction(), ci))
        end
    end

    # Retrieve Variable Domain
    # Assuming: 𝕊, 𝔹 ⊆ Ω
    if !isempty(𝕊) && !isempty(𝔹)
        qubo_parsing_error("The given model contains both boolean and spin variables.\n")
    elseif isempty(𝕊) # QUBO model?
        if 𝔹 != Ω
            qubo_parsing_error("Not all variables in the given model are boolean.\n")
        else
            return _extract_bool_model(T, model, Ω)
        end
    else # isempty(𝔹) # Ising model?
        if 𝕊 != Ω
            qubo_parsing_error("Not all variables in the given model are spin.\n")
        else
            return _extract_spin_model(T, model, Ω)
        end
    end
end

function _extract_bool_model(
    ::Type{T},
    model::MOI.ModelLike,
    Ω::Set{VI},
) where {T}
    L = Dict{VI,T}(xi => zero(T) for xi ∈ Ω)
    Q = Dict{Tuple{VI,VI},T}()
    
    β = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        L[f] += one(T)
    elseif F <: SAF
        for a in f.terms
            ci = a.coefficient
            xi = a.variable

            L[xi] += ci
        end

        β += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            ci = a.coefficient
            xi = a.variable

            L[xi] += ci
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
                L[xi] += cij / 2
            else
                Q[xi, xj] = get(Q, (xi, xj), zero(T)) + cij
            end
        end

        β += f.constant
    end

    return QUBOTools.Model{VI,T,Int}(
        L, Q;
        offset = β,
        sense  = QUBOTools.sense(MOI.get(model, MOI.ObjectiveSense())),
        domain = :bool,
    )
end

function _extract_spin_model(
    ::Type{T},
    model::MOI.ModelLike,
    Ω::Set{VI},
) where {T}
    L = Dict{VI,T}(xi => zero(T) for xi ∈ Ω)
    Q = Dict{Tuple{VI,VI},T}()

    β = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        L[f] += one(T)
    elseif F <: SAF
        for a in f.terms
            ci = a.coefficient
            xi = a.variable

            L[xi] += ci
        end

        β += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            ci = a.coefficient
            xi = a.variable

            L[xi] += ci
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
            else
                Q[xi, xj] = get(Q, (xi, xj), zero(T)) + cij
            end
        end

        β += f.constant
    end

    return QUBOTools.Model{VI,T,Int}(
        L, Q;
        offset = β,
        sense  = QUBOTools.sense(MOI.get(model, MOI.ObjectiveSense())),
        domain = :spin,
    )
end
