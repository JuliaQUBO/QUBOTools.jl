const BinaryDomain = Union{MOI.ZeroOne,Spin}

@doc raw"""
    QUBOModel{T,C}

This is a MathOptInterface model for QUBO problems. 
"""
mutable struct QUBOModel{T,C<:BinaryDomain} <: MOI.ModelLike
    objective_function::SQF{T}
    objective_sense::MOI.OptimizationSense
    variables::Vector{VI}

    function QUBOModel{T,C}() where {T,C<:BinaryDomain}
        return new{T,C}(SQF{T}(SQT{T}[], SAT{T}[], zero(T)), MOI.MIN_SENSE, VI[])
    end
end

# The function takes no arguments and returns the QUBOModel type. Other
# packages will assign its return value to a constant, e.g.,
#
#     const QUBOModel = QUBOTools.__moi_qubo_model()
#
QUBOTools.__moi_qubo_model() = QUBOModel

function QUBOModel{T}() where {T}
    return QUBOModel{T,MOI.ZeroOne}()
end

function QUBOModel()
    return QUBOModel{Float64,MOI.ZeroOne}()
end

# MOI Wrapper
function MOI.get(model::QUBOModel, ::MOI.NumberOfVariables)
    return length(model.variables)
end

function MOI.add_variable(model::QUBOModel{T,C}) where {T,C<:BinaryDomain}
    vi = VI(MOI.get(model, MOI.NumberOfVariables()) + 1)

    push!(model.variables, vi)

    return vi
end

function MOI.add_constraint(::QUBOModel{T,C}, vi::VI, ::C) where {T,C<:BinaryDomain}
    return CI{VI,C}(vi.value)
end

function MOI.is_empty(model::QUBOModel)
    return isempty(model.variables) &&
           isempty(model.objective_function.quadratic_terms) &&
           isempty(model.objective_function.affine_terms) &&
           iszero(model.objective_function.constant)
end

function MOI.empty!(model::QUBOModel{T}) where {T}
    model.objective_function = SQF{T}(SQT{T}[], SAT{T}[], zero(T))
    model.objective_sense    = MOI.MIN_SENSE

    empty!(model.variables)

    return nothing
end

# Support
MOI.supports(
    ::QUBOModel{T},
    ::MOI.ObjectiveFunction{F},
) where {T,F<:Union{VI,SAF{T},SQF{T}}} = true

MOI.supports_constraint(::QUBOModel{T,C}, ::Type{VI}, ::Type{C}) where {T,C<:BinaryDomain}   = true
MOI.supports_add_constrained_variable(::QUBOModel{T,C}, ::Type{C}) where {T,C<:BinaryDomain} = true

# get & set
function MOI.get(model::QUBOModel, ::MOI.ObjectiveSense)
    return model.objective_sense
end

function MOI.set(
    model::QUBOModel,
    ::MOI.ObjectiveSense,
    objective_sense::MOI.OptimizationSense,
)
    model.objective_sense = objective_sense

    return nothing
end

function MOI.get(model::QUBOModel{T}, ::MOI.ObjectiveFunction{SQF{T}}) where {T}
    return model.objective_function
end

function MOI.set(model::QUBOModel{T}, ::MOI.ObjectiveFunction{VI}, vi::VI) where {T}
    model.objective_function = SQF{T}(SQT{T}[], SAT{T}[SAT{T}(one(T), vi)], zero(T))

    return nothing
end

function MOI.set(model::QUBOModel{T}, ::MOI.ObjectiveFunction{SAF{T}}, f::SAF{T}) where {T}
    model.objective_function = SQF{T}(SQT{T}[], copy(f.terms), f.constant)

    return nothing
end

function MOI.set(model::QUBOModel{T}, ::MOI.ObjectiveFunction{SQF{T}}, f::SQF{T}) where {T}
    model.objective_function = SQF{T}( #
        copy(f.quadratic_terms),
        copy(f.affine_terms),
        f.constant,
    )

    return nothing
end

MOI.get(::QUBOModel{T}, ::MOI.ObjectiveFunctionType) where {T} = SQF{T}

function MOI.get(
    model::QUBOModel{T,C},
    ::MOI.ListOfConstraintTypesPresent,
) where {T,C<:BinaryDomain}
    if MOI.is_empty(model)
        return []
    else
        return [(VI, C)]
    end
end

function MOI.get(
    model::QUBOModel{T,C},
    ::MOI.ListOfConstraintIndices{VI,C},
) where {T,C<:BinaryDomain}
    return [CI{VI,C}(vi.value) for vi in model.variables]
end

function MOI.get(model::QUBOModel, ::MOI.ListOfVariableIndices)
    return model.variables
end

function MOI.get(
    ::QUBOModel{T,C},
    ::MOI.ConstraintFunction,
    ci::CI{VI,C},
) where {T,C<:BinaryDomain}
    return VI(ci.value)
end

function MOI.get(
    ::QUBOModel{T,C},
    ::MOI.ConstraintSet,
    ::CI{VI,C},
) where {T,C<:BinaryDomain}
    return C()
end

function MOI.get(::QUBOModel{T,C}, ::MOI.VariableName, vi::VI) where {T,C<:BinaryDomain}
    if C === MOI.ZeroOne
        return "x[$(vi.value)]"
    else # C === Spin
        return "s[$(vi.value)]"
    end
end
