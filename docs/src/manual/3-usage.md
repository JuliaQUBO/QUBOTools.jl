# Basic Usage

```@example manual
using QUBOTools
```

By loading the package with the `using` statement, only a few constants will be dumped in the namespace, most of them model types.

## File I/O

To read and write models one should use the [`QUBOTools.read_model`](@ref)/[`QUBOTools.write_model`](@ref) API.

```@example manual
# File Path
path = joinpath(@__DIR__, "data", "problem.json")

model = QUBOTools.read_model(path)
```

!!! info
    The [`QUBOTools.read_model`](@ref) and [`QUBOTools.write_model`](@ref) methods will try to infer the file format from the file extension.
    The format can be manually set by passing an extra optional parameter after the source path.
    For more information, see [File Formats](@ref).

## Data Access

```@example manual
QUBOTools.description(model)
```

```@example manual
QUBOTools.linear_terms(model) |> collect
```

```@example manual
QUBOTools.quadratic_terms(model) |> collect
```

### Model Analysis

```@example manual
QUBOTools.density(model)
```

## File formats

### Conversion between formats

One of the main functionalities of this package is to allow fast conversion from a QUBO file format to another.
Achieving this is as simple as writing the loaded model but providing a different specification:

```@example manual
QUBOTools.write_model(stdout, model, QUBOTools.Qubist())
```
