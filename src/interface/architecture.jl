@doc raw"""
    AbstractArchitecture
"""
abstract type AbstractArchitecture end

@doc raw"""
    architecture(::Any)

It should be defined to provide automatic architecture recognition when writing
QUBO Solver interfaces.

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
