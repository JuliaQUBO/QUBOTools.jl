# API Reference

## Fallback dispatch

When extending `QUBOTools`, one might want to implement a method for [`QUBOTools.backend`](@ref).

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
```

```@docs
QUBOTools.AbstractSolution
QUBOTools.SampleSet
QUBOTools.solution
```

```@docs
QUBOTools.state
QUBOTools.value
QUBOTools.energy
QUBOTools.reads
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
