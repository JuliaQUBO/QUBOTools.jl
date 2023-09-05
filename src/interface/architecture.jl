@doc raw"""
    AbstractArchitecture
"""
abstract type AbstractArchitecture end

@doc raw"""
    architecture(::Any)

This function makes it possible to infer the solver's architecture from its type.
It should be defined to provide automatic architecture recognition when writing QUBO Solvers.

## Example

```julia
struct Solver
    ...
end

struct SolverArchitecture <: AbstractArchitecture
    ...
end

architecture(::Solver) = SolverArchitecture()
```
"""
function architecture end

@doc raw"""
    layout(::Any)

Returns the layout of a device or architecture, i.e., a mapping between integers
identifying nodes and their spatial position.
"""
function layout end
