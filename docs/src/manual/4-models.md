# Models

## Backend

The `AbstractModel{V,T}` abstract type is defined, where `V` is the type for indexing variable and `T` the one for representing the problem's coefficients.

QUBOTools also exports the ``Model{V,T,U} <: AbstractModel{V,T}`` type, designed to work as a powerful standard backend for all other models.
Here, `V` plays the role of variable indexing type and usually is `Int` or `Symbol`.
It is followed by `U <: Integer`, used to store sampled state vectors as `Vector{U}` within `SampleSet{T,U}`.

`T <: Real` is the type used to represent all coefficients.
It is also the choice for the energy values corresponding to each solution.
It's commonly set as `Float64`.

## JuMP Integration

One of the main milestones was to make [JuMP](https://jump.dev) / [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl) integration easy.
When `V` is set to `MOI.VariableIndex` and `T` matches `Optimzer{T}`, the QUBOTools backend is able to handle most of the data management workload.