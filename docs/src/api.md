# API Reference

## Fallback dispatch

When extending `QUBOTools`, one must implement a method for [`QUBOTools.backend`](@ref). 

```@docs
QUBOTools.backend
```

## Variable System

```@docs
QUBOTools.varlt
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
QUBOTools.Min
QUBOTools.Max
QUBOTools.sense
```

## Frame Casting

```@docs
QUBOTools.Frame
QUBOTools.cast
```

## Solution Interface

```@docs
QUBOTools.Sample{T,U}
QUBOTools.SampleSet{T,U}
QUBOTools.solution
```

```@docs
QUBOTools.state
QUBOTools.value
QUBOTools.reads
QUBOTools.energy
```

## Models

```@docs
QUBOTools.AbstractModel{V,T,U}
QUBOTools.Model{V,T,U}
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
QUBOTools.variables
QUBOTools.variable_set
QUBOTools.variable_map
QUBOTools.variable_inv
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
QUBOTools.topology
QUBOTools.adjacency
```

## Normal Forms

```@docs
QUBOTools.DictForm{T}
QUBOTools.SparseForm{T}
QUBOTools.DenseForm{T}
QUBOTools.form
```

```@docs
QUBOTools.qubo
QUBOTools.ising
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

### Time-to-Solution (TTS)

```@docs
QUBOTools.tts
```

### Optimal Time-to-Solution (TTS)

```@docs
QUBOTools.opt_tts
```