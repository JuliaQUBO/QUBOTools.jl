@doc raw"""
    Model{V,T,U} <: AbstractModel{V,T,U}

Reference [`AbstractModel`](@ref) implementation.

It is intended to be the core engine behind the target codecs.

## MathOptInterface/JuMP

Both `V <: Any` and `T <: Real` parameters exist to support MathOptInterface/JuMP integration.
By choosing `V = MOI.VariableIndex` and `T` matching `Optimizer{T}` the hard work should be done.

"""
mutable struct Model{V,T,U} <: AbstractModel{V,T,U}
    # Coefficients & Factors
    form::NormalForm{T}
    # Variable Mapping
    variable_map::Dict{V,Int}
    variable_inv::Vector{V}
    # Sense & Domain
    frame::Frame
    # Metadata
    metadata::Dict{String,Any}
    # Solution
    solution::SampleSet{T,U}
    # Hints
    start::Dict{Int,U}
end

function form(model::Model; domain = QUBOTools.domain(model))
    return cast(QUBOTools.domain(model) => domain, model.form)
end

dimension(model::Model)       = dimension(form(model))
linear_terms(model::Model)    = linear_terms(form(model))
quadratic_terms(model::Model) = quadratic_terms(form(model))
scale(model::Model)           = scale(form(model))
offset(model::Model)          = offset(form(model))

frame(model::Model)     = model.frame
sense(model::Model)     = sense(frame(model))
domain(model::Model)    = fomain(frame(model))

variable_map(model::Model)    = model.variable_map
variable_inv(model::Model)    = model.variable_inv

metadata(model::Model) = model.metadata
solution(model::Model) = model.solution

function start(model::Model, index::Integer; domain = QUBOTools.domain(model))
    if haskey(model.start, index)
        return cast(QUBOTools.domain(model) => domain, model.start[index])
    else
        return nothing
    end
end

function start(model::Model{T,V,U}; domain = QUBOTools.domain(model)) where {T,V,U}
    return Dict{Int,U}(i => start(model, i; domain) for i in keys(model.start))
end
