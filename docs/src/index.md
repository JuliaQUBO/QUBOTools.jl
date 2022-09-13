# QUBOTools.jl

## Introduction
The `QUBOTools.jl` package implements codecs and queries for QUBO (*Quadratic Unconstrained Binary Optimization*) instances.
Its purpose is to provide fast and reliable conversion between common formats used to represent such problems.
This allows for rapid leverage of many emergent computing architectures whose job is to solve this kind of optimization problem.

The term QUBO is widely used when referring to *boolean* problems of the form

```math
\begin{array}{rl}
       \min & \vec{x}'\ Q\ \vec{x} \\
\text{s.t.} & \vec{x} \in \mathbb{B}^{n}
\end{array}
```

with symmetric ``Q \in \mathbb{R}^{n \times n}``
Nevertheless, this package also fully supports *Ising Models*, given by

```math
\begin{array}{rl}
       \min & \vec{s}'\ J\ \vec{s} + \vec{h}'\ \vec{s} \\
\text{s.t.} & \vec{s} \in \left\lbrace-1, 1\right\rbrace^{n}
\end{array}
```

where ``J \in \mathbb{R}^{n \times n}`` is triangular and ``\vec{h} \in \mathbb{R}^{n}``.

## Objectives
The objectives of this package is to provide:
- Fast and reliable I/O, including conversion between formats
- Model & Solution Analysis through data queries and metrics
- Generic yet complete backend for powering other applications