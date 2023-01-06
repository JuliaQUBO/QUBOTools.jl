# [API Reference](@id api-reference)

### Fallback dispatch
When extending `QUBOTools`, one must implement a method for [`QUBOTools.backend`](@ref). 

```@docs
QUBOTools.backend
```

### Variable System
```@docs
QUBOTools.varlt
```

### Variable Domains
```@docs
QUBOTools.Domain
QUBOTools.BoolDomain
QUBOTools.SpinDomain
QUBOTools.UnknownDomain
QUBOTools.domain
QUBOTools.sense
```

### Frame Casting
```@docs
QUBOTools.cast
```

### Solution Interface
```@docs
QUBOTools.Sample
QUBOTools.SampleSet
QUBOTools.sampleset
```

```@docs
QUBOTools.state
QUBOTools.value
QUBOTools.energy
QUBOTools.reads
```

### Models
```@docs
QUBOTools.AbstractModel
QUBOTools.Model
QUBOTools.model_name
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

### Queries
```@docs
QUBOTools.domain_size
QUBOTools.linear_size
QUBOTools.quadratic_size
QUBOTools.density
QUBOTools.linear_density
QUBOTools.quadratic_density
QUBOTools.adjacency
```

### Normal Forms
```@docs
QUBOTools.qubo
QUBOTools.ising
```