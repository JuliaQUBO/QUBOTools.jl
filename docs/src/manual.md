# Manual

## Introduction

```@example manual
using QUBOTools
```

## Basic File I/O
To read and write QUBO models one is expected to use the `Base.read`/`Base.write` API.

```@example manual
# File Path
fpath = joinpath(@__DIR__, "data", "problem.json")

model = read(fpath, BQPJSON)
```

## Data Access

```@example manual
QUBOTools.linear_terms(model)
```

```@example manual
QUBOTools.quadratic_terms(model)
```

## Conversion between File Formats
One of the main functionalities of this package is to allow fast conversion from a QUBO file format to another.
As a design choice, *QUBOTools* leverages the `Base.convert` interface to perform this task.

```@example manual
qubo_model = convert(QUBO, model)
```

It can also be used to switch between variable domains:

```@example manual
spin_model = convert(BQPJSON{SpinDomain}, model)
```