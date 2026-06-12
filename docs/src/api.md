# API Reference

## Fallback dispatch

When extending `QUBOTools`, one might want to implement a method for [`QUBOTools.backend`](@ref).

For MathOptInterface/JuMP integrations, including ToQUBO workflows that expose
an `MOI.ModelLike` object, the supported public materialization path is:

```julia
qt_model = QUBOTools.Model(moi_model)
```

Use `backend` for wrapper types that already own or can return a
`QUBOTools.AbstractModel`; use `QUBOTools.Model(moi_model)` when the source is an
MOI model that needs to be converted into QUBOTools' sparse in-memory
representation.

```@docs
QUBOTools.backend
```

## Variable System

```@docs
QUBOTools.index
QUBOTools.indices
QUBOTools.hasindex
QUBOTools.variable
QUBOTools.variables
QUBOTools.hasvariable
```

```@docs
QUBOTools.VariableMap
```

```@docs
QUBOTools.PBO.varlt
```

## Objective & Domain Frames

```@docs
QUBOTools.Domain
QUBOTools.BoolDomain
QUBOTools.SpinDomain
QUBOTools.domain
```

```@docs
QUBOTools.Sense
QUBOTools.sense
```

```@docs
QUBOTools.Frame
QUBOTools.frame
QUBOTools.cast
```

### Errors

```@docs
QUBOTools.CastingError
```

## Models

```@docs
QUBOTools.AbstractModel
QUBOTools.Model
```

## Model Forms

```@docs
QUBOTools.AbstractForm
QUBOTools.AbstractLinearForm
QUBOTools.AbstractQuadraticForm
QUBOTools.form
QUBOTools.linear_form
QUBOTools.quadratic_form
```

```@docs
QUBOTools.qubo
QUBOTools.ising
```

```@docs
QUBOTools.fix_variables
QUBOTools.lift_state
```

### Underlying Data Structures

```@docs
QUBOTools.Form
QUBOTools.formtype
```

```@docs
QUBOTools.DictForm
QUBOTools.DictLinearForm
QUBOTools.DictQuadraticForm
```

```@docs
QUBOTools.DenseForm
QUBOTools.DenseLinearForm
QUBOTools.DenseQuadraticForm
```

```@docs
QUBOTools.SparseForm
QUBOTools.SparseLinearForm
QUBOTools.SparseQuadraticForm
```

## Solutions

```@docs
QUBOTools.State
```

```@docs
QUBOTools.AbstractSample
QUBOTools.Sample
QUBOTools.sample
QUBOTools.hassample
```

```@docs
QUBOTools.AbstractSolution
QUBOTools.SampleSet
QUBOTools.solution
QUBOTools.sampleset_table
```

```@docs
QUBOTools.state
QUBOTools.value
QUBOTools.energy
QUBOTools.reads
```

```@docs
QUBOTools.ObjectiveBreakdown
QUBOTools.ObjectiveMismatch
QUBOTools.objective_breakdown
QUBOTools.annotate_objectives!
QUBOTools.objective_value_mismatches
QUBOTools.verify_objective_values
```

### Solution Errors

```@docs
QUBOTools.SolutionError
```

## Data Access

```@docs
QUBOTools.linear_terms
QUBOTools.quadratic_terms
QUBOTools.scale
QUBOTools.offset
```

```@docs
QUBOTools.data
```

```@docs
QUBOTools.metadata
QUBOTools.id
QUBOTools.description
```

```@docs
QUBOTools.start
```

```@docs
QUBOTools.attach!
```

## File Formats & I/O

```@docs
QUBOTools.AbstractFormat
QUBOTools.format
QUBOTools.version
```

```@docs
QUBOTools.read_model
QUBOTools.write_model
```

```@docs
QUBOTools.read_solution
QUBOTools.write_solution
QUBOTools.read_samples
QUBOTools.write_samples
```

### Format & I/O Errors

```@docs
QUBOTools.FormatError
QUBOTools.SyntaxError
```

## Model Metrics

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
QUBOTools.geometry
```

## System Specification

```@docs
QUBOTools.AbstractArchitecture
QUBOTools.GenericArchitecture
QUBOTools.architecture
```

```@docs
QUBOTools.AbstractDevice
QUBOTools.GenericDevice
```

```@docs
QUBOTools.Layout
QUBOTools.layout
```

## Problem Synthesis

```@docs
QUBOTools.AbstractProblem
QUBOTools.generate
```

```@docs
QUBOTools.SherringtonKirkpatrick
QUBOTools.Wishart
```

## Solution Metrics

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

### Hamming Distance

```@docs
QUBOTools.hamming_distance
```

## Visualization

```@docs
QUBOTools.AbstractVisualization
```
