# API Reference

## Fallback dispatch

When extending `QUBOTools`, one must implement a method for [`QUBOTools.backend`](@ref).

```@docs
QUBOTools.backend
```

## Variable System

```@docs
QUBOTools.index
QUBOTools.indices
QUBOTools.variable
QUBOTools.variables
```

```@docs
QUBOTools.PBO.varlt
```

## Variable Domains

```@docs
QUBOTools.Domain
QUBOTools.BoolDomain
QUBOTools.SpinDomain
QUBOTools.domain
```

## Objective Sense

```@docs
QUBOTools.Sense
QUBOTools.sense
```

## Frame Casting

```@docs
QUBOTools.Frame
QUBOTools.cast
```

## Solution Interface

```@docs
QUBOTools.Sample
QUBOTools.SampleSet
QUBOTools.solution
```

```@docs
QUBOTools.state
QUBOTools.value
QUBOTools.energy
QUBOTools.reads
```

## Models

```@docs
QUBOTools.AbstractModel
QUBOTools.Model
```

```@docs
QUBOTools.AbstractFormat
QUBOTools.format
```

## Data Access

```@docs
QUBOTools.linear_terms
QUBOTools.quadratic_terms
QUBOTools.scale
QUBOTools.offset
```

```@docs
QUBOTools.metadata
QUBOTools.id
QUBOTools.description
```

## I/O

```@docs
QUBOTools.read_model
QUBOTools.write_model
```

```@docs
QUBOTools.read_solution
QUBOTools.write_solution
```

## Metrics and other queries

```@docs
QUBOTools.dimension
QUBOTools.linear_size
QUBOTools.quadratic_size
QUBOTools.density
QUBOTools.linear_density
QUBOTools.quadratic_density
```

```@docs
QUBOTools.topology
QUBOTools.adjacency
```

## Normal Forms

```@docs
QUBOTools.form
```

```@docs
QUBOTools.qubo
QUBOTools.ising
```

```@docs
QUBOTools.DictForm{T}
QUBOTools.SparseForm{T}
QUBOTools.DenseForm{T}
```

## Benchmarking

### Timing

```@docs
QUBOTools.total_time
QUBOTools.effective_time
```

### Solution Quality

```@docs
QUBOTools.success_rate
```

### Time-to-Target (TTT)

```@docs
QUBOTools.time_to_target
QUBOTools.ttt
```
