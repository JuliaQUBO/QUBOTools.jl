# Models

This package defines [`AbstractModel{V,T,U}`](@ref) as an abstract type for QUBO models.
`V` is a type for indexing variables, usually an integer or string-like type.
The problem's coefficients are stored under the `T` type, that also represents the energy values corresponding to each solution.
When solution state vectors are sampled, their entries will be of the integer type `U`.

## Standard Model Implementation

QUBOTools also exports the `Model{V,T,U} <: AbstractModel{V,T,U}` type, designed to work as standard backend for other applications to be built atop.

## Model Backend

```@example model-backend
using QUBOTools

mutable struct SuperModel{V,T,U} <: QUBOTools.AbstractModel{V,T,U}
    model::QUBOTools.Model{V,T,U}
    super::Bool

    function SuperModel{V,T,U}() where {V,T,U}
        return new(QUBOTools.Model{V,T,U}(), true)
    end
end

QUBOTools.backend(model::SuperModel) = model.model
```

```@example model-backend
model = SuperModel{Symbol,Float64,Int}()
```

## JuMP Integration

One of the main milestones was to make [JuMP](https://jump.dev) / [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl) integration easy.
When `V` is set to `MOI.VariableIndex` and `T` matches `Optimzer{T}`, the QUBOTools backend is able to handle most of the data management workload.
