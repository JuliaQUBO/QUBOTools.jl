@doc raw"""
    AbstractArchitecture
"""
abstract type AbstractArchitecture end

@doc raw"""
    GenericArchitecture()

This type is used to reach fallback implementations for [`AbstractArchitecture`](@ref) and, therefore,
should not have any methods directely related to it.
"""
struct GenericArchitecture <: AbstractArchitecture end

@doc raw"""
    infer_architecture(::Any)

Tries to infer the solver's architecture from its type.
It should be defined to provide automatic architecture recognition when writing QUBO Solvers.

## Example

```julia
struct Solver
    ...
end

struct SolverArchitecture <: AbstractArchitecture
    ...
end

infer_architecture(::Solver) = SolverArchitecture()
```
"""
function infer_architecture end

infer_architecture(::Any) = GenericArchitecture()
