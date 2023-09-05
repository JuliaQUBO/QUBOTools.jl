# QUBOTools.jl

## Introduction

The `QUBOTools.jl` package implements codecs and query methods for working with [QUBO](https://en.wikipedia.org/wiki/Quadratic_unconstrained_binary_optimization) instances.
Its purpose is to provide fast and reliable conversion between common formats used to represent such problems.
This allows for rapid leverage of many emergent computing architectures whose job is to solve this kind of optimization problem.

The _QUBO_ term, in the strict sense, is widely used to indicate *boolean* problems of the form

```math
\begin{array}{rl}
       \min & \mathbf{x}'\ Q\ \mathbf{x} \\
\text{s.t.} & \mathbf{x} \in \mathbb{B}^{n}
\end{array}
```

with symmetric ``Q \in \mathbb{R}^{n \times n}``.
Nevertheless, this package also provides full support for _Ising Models_, given by

```math
\begin{array}{rl}
       \min & \mathbf{s}'\ J\ \mathbf{s} + \mathbf{h}'\ \mathbf{s} \\
\text{s.t.} & \mathbf{s} \in \left\lbrace-1, 1\right\rbrace^{n}
\end{array}
```

where ``J \in \mathbb{R}^{n \times n}`` is upper triangular and ``\mathbf{h} \in \mathbb{R}^{n}``.

## Installation

QUBOTools is avaible through Julia's General Registry:

```julia-repl
julia> import Pkg

julia> Pkg.add("QUBOTools")

julia> using QUBOTools
```

## Design Goals

The objective of this package is to provide:

- Fast and reliable I/O, including conversion between formats.
- Model & Solution Analysis through data queries, metrics and plot recipes.
- Generic yet complete backend for powering other applications.
- Synthetic problem generation.