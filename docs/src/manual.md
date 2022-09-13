# Manual

## Introduction
This manual aims to explain the fundamental concepts behind loading and manipulating QUBO models.

```@example manual
using QUBOTools
```

## Mathematical Formulation
The conventions adopted by `QUBOTools.jl` are built over models of the form

```math
\begin{array}{rl}
    \text{QUBO}: \min & \alpha \left[{ \mathbf{x}' Q\, \mathbf{x} + \mathbf{\ell}' \mathbf{x} + \beta }\right] \\[1ex]
          \text{s.t.} & \mathbf{x} \in S \cong \mathbb{B}^{n}
\end{array}
```

where ``\alpha, \beta \in \mathbb{R}`` and ``\mathbf{\ell} \in \mathbb{R}^{n}`.
``Q \in \mathbb{R}^{n \times n}`` is assumed to be in its triangular superior form.

!!! info
    Any problem loaded with this package will be converted internally to the normal form presented above.

!!! info
    The scaling factor ``\alpha`` is assumed to be positive in the minimization sense.
    Negative values are used to indicate maximization problems.

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