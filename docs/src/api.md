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
QUBOTools.MinSense
QUBOTools.MaxSense
QUBOTools.sense
```

## Frame Casting

```@docs
QUBOTools.cast
```

## Solution Interface

```@docs
QUBOTools.Sample
QUBOTools.SampleSet{T,U}
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
QUBOTools.AbstractModel{V,T,U}
QUBOTools.Model{V,T,U}
```

```@docs
QUBOTools.AbstractFormat
QUBOTools.infer_format
```

## Data Access

```@docs
QUBOTools.linear_terms
QUBOTools.explicit_linear_terms
QUBOTools.quadratic_terms
QUBOTools.scale
QUBOTools.offset
```

```@docs
QUBOTools.variable_map
QUBOTools.variable_inv
QUBOTools.variable_set
QUBOTools.variables
```

```@docs
QUBOTools.id
QUBOTools.version
QUBOTools.description
QUBOTools.metadata
```

## I/O

```@docs
QUBOTools.read_model
QUBOTools.write_model
```

## Metrics and other queries

```@docs
QUBOTools.dimension
QUBOTools.linear_size
QUBOTools.quadratic_size
QUBOTools.density
QUBOTools.linear_density
QUBOTools.quadratic_density
QUBOTools.adjacency
```

## Normal Forms

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