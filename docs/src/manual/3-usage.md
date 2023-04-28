# Basic Usage

```@example manual
using QUBOTools
```

By loading the package with the `using` statement, only a few constants will be dumped in the namespace, most of them model types.

## Basic File I/O
To read and write QUBO models one is expected to use the `Base.read`/`Base.write` API.

```@example manual
# File Path
fpath = joinpath(@__DIR__, "data", "problem.json")

model = read(fpath, BQPJSON())
```

## Data Access
When querying a model, one should rely on the provided methods, whose definitions are listed in the [API Reference](@ref api-reference).

```@example manual
QUBOTools.description(model)
```

```@example manual
QUBOTools.linear_terms(model)
```

```@example manual
QUBOTools.quadratic_terms(model)
```

## File formats

### Conversion between formats
One of the main functionalities of this package is to allow fast conversion from a QUBO file format to another.
Achieving this is as simple as writing the loaded model but providing a different specification:

```@example manual
write("problem.qubo", model, QUBO())
```

It can also be used to switch between variable domains while keeping the file format unchanged:

```@example manual
write("problem.json", model, BQPJSON(SpinDomain()))
```
