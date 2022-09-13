# API Reference

### Fallback dispatch
When extending `QUBOTools`, one must implement a method for [`QUBOTools.backend`](@ref). 

```@docs
QUBOTools.backend
```

### Variable System
```@docs
QUBOTools.varcmp
```

### Variable Domains
```@docs
QUBOTools.VariableDomain
QUBOTools.BoolDomain
QUBOTools.SpinDomain
QUBOTools.domain
QUBOTools.domain_name
QUBOTools.swap_domain
```

### Solution Interface
```@docs
QUBOTools.Sample
QUBOTools.SampleSet
QUBOTools.sampleset
```

```@docs
QUBOTools.state
QUBOTools.reads
QUBOTools.energy
```

### Models
```@docs
QUBOTools.AbstractQUBOModel
QUBOTools.StandardQUBOModel
QUBOTools.model_name
QUBOTools.infer_model_type
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