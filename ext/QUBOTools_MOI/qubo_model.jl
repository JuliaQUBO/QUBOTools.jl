const BinaryDomain = Union{MOI.ZeroOne,Spin}

@doc raw"""
    QUBOModel{T,C}

This is a MathOptInterface model for QUBO problems. 
"""
mutable struct QUBOModel{T,C<:BinaryDomain} <: MOI.ModelLike
    objective_function::SQF{T}
    objective_sense::MOI.OptimizationSense
    variables::Vector{VI}
    fixed::Dict{VI,T}

    function QUBOModel{T,C}() where {T,C<:BinaryDomain}
        return new{T,C}(SQF{T}(SQT{T}[], SAT{T}[], zero(T)), MOI.MIN_SENSE, VI[], Dict{VI,T}())
    end
end

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

function MOI.add_constraint(
    model::QUBOModel{T,C},
    vi::VI,
    et::MOI.EqualTo{T},
) where {T,C<:BinaryDomain}
    model.fixed[vi] = et.value

    return CI{VI,MOI.EqualTo{T}}(vi.value)
end

function MOI.add_constrained_variable(model::QUBOModel{T,C}, c::C) where {T,C<:BinaryDomain}
    vi = MOI.add_variable(model)
    ci = MOI.add_constraint(model, vi, c)

    return (vi, ci)
end

function MOI.add_constrained_variable(::QUBOModel{T,X}, ::Y) where {T,X<:BinaryDomain,Y<:BinaryDomain}
    error("Can't add variable of type '$Y' to model with variables of type '$X'")

    return nothing
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
    empty!(model.fixed)

    return nothing
end

# Support
MOI.supports(
    ::QUBOModel{T},
    ::MOI.ObjectiveFunction{F},
) where {T,F<:Union{VI,SAF{T},SQF{T}}} = true

MOI.supports_constraint(::QUBOModel{T,C}, ::Type{VI}, ::Type{C}) where {T,C<:BinaryDomain}                = true
MOI.supports_constraint(::QUBOModel{T,C}, ::Type{VI}, ::Type{MOI.EqualTo{T}}) where {T,C<:BinaryDomain}   = true
MOI.supports_add_constrained_variable(::QUBOModel{T,C}, ::Type{C}) where {T,C<:BinaryDomain}              = true
# MOI.supports_add_constrained_variable(::QUBOModel{T,C}, ::Type{MOI.EqualTo{T}}) where {T,C<:BinaryDomain} = true

# get & set
function MOI.get(model::QUBOModel, ::MOI.ObjectiveSense)
    return model.objective_sense
end

function MOI.set(
    model::QUBOModel,
    ::MOI.ObjectiveSense,
    objective_sense::MOI.OptimizationSense,
)
    @assert objective_sense === MOI.MIN_SENSE || objective_sense === MOI.MAX_SENSE

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
    list = []

    if !isempty(model.variables)
        push!(list, (VI, C))
    end

    if !isempty(model.fixed)
        push!(list, (VI, MOI.EqualTo{T}))
    end

    return list
end

function MOI.get(
    model::QUBOModel{T,C},
    ::MOI.ListOfConstraintIndices{VI,C},
) where {T,C<:BinaryDomain}
    return [CI{VI,C}(vi.value) for vi in model.variables]
end

function MOI.get(
    model::QUBOModel{T,C},
    ::MOI.ListOfConstraintIndices{VI,MOI.EqualTo{T}},
) where {T,C<:BinaryDomain}
    return [CI{VI,MOI.EqualTo{T}}(vi.value) for vi in keys(model.fixed)]
end

function MOI.get(model::QUBOModel, ::MOI.ListOfVariableIndices)
    return collect(model.variables)
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

function MOI.get(
    ::QUBOModel{T,C},
    ::MOI.ConstraintFunction,
    ci::CI{VI,MOI.EqualTo{T}},
) where {T,C<:BinaryDomain}
    return VI(ci.value)
end

function MOI.get(
    model::QUBOModel{T,C},
    ::MOI.ConstraintSet,
    ci::CI{VI,MOI.EqualTo{T}},
) where {T,C<:BinaryDomain}
    return MOI.EqualTo{T}(model.fixed[VI(ci.value)])
end

function MOI.get(::QUBOModel{T,C}, ::MOI.VariableName, vi::VI) where {T,C<:BinaryDomain}
    if C === MOI.ZeroOne
        return "x[$(vi.value)]"
    else # C === Spin
        return "s[$(vi.value)]"
    end
end
