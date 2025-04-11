# QUBOTools.jl

<div align="center">
    <a href="/docs/src/assets/">
        <img src="/docs/src/assets/logo.svg" width=400px alt="QUBOTools.jl" />
    </a>
    <br>
    <a href="https://arxiv.org/abs/2307.02577">
        <img src="https://img.shields.io/badge/arXiv-2307.02577-b31b1b.svg" alt="arXiv"/>
    </a>
    <a href="https://codecov.io/gh/psrenergy/QUBOTools.jl" > 
        <img src="https://codecov.io/gh/JuliaQUBO/QUBOTools.jl/branch/main/graph/badge.svg?token=W7QJWS5HI4"/> 
    </a>
    <a href="/actions/workflows/ci.yml">
        <img src="https://github.com/JuliaQUBO/QUBOTools.jl/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI" />
    </a>
    <a href="https://www.youtube.com/watch?v=OTmzlTbqdNo">
        <img src="https://img.shields.io/badge/JuliaCon-2022-9558b2" alt="JuliaCon 2022">
    </a>
    <a href="https://juliaqubo.github.com/QUBOTools.jl/dev">
        <img src="https://img.shields.io/badge/docs-dev-blue.svg" alt="Docs">
    </a>
    <a href="https://zenodo.org/badge/latestdoi/508908129">
        <img src="https://zenodo.org/badge/508908129.svg" alt="DOI">
    </a>
    <br>
    <i>Tools for Quadratic Unconstrained Binary Optimization models in Julia</i>
</div>

## Introduction
The `QUBOTools.jl` package implements codecs for QUBO (*Quadratic Unconstrained Binary Optimization*) instances.
Its purpose is to provide fast and reliable conversion between common formats used to represent such problems.
This allows for rapid leverage of many emergent computing architectures whose job is to solve this kind of optimization problem.

The term QUBO is widely used when referring to *boolean* problems of the form

$$\begin{array}{rl}
       \min & \mathbf{x}'\ Q\ \mathbf{x} \\
\text{s.t.} & \mathbf{x} \in \mathbb{B}^{n}
\end{array}$$

with symmetric $Q \in \mathbb{R}^{n \times n}$. Nevertheless, this package also fully supports *Ising Models*, given by

$$\begin{array}{rl}
       \min & \mathbf{s}'\ J\ \mathbf{s} + \mathbf{h}'\ \mathbf{s} \\
\text{s.t.} & \mathbf{s} \in \left\lbrace-1, 1\right\rbrace^{n}
\end{array}$$

where $J \in \mathbb{R}^{n \times n}$ is triangular and $\mathbf{h} \in \mathbb{R}^{n}$.

## Getting Started

### Installation

```julia
import Pkg

Pkg.add("QUBOTools")
```

### Basic Usage

```julia
using QUBOTools

model = QUBOTools.read_model("problem.json")

QUBOTools.write_model("problem.qubo", model)
```

## Supported Formats

|              Format                | Read  | Write | Model | Solutions | Start | Metadata |
| :--------------------------------: | :---: | :---: | :---: | :-------: | :---: | :------: |
| [BQPJSON](https://juliaqubo.github.com/QUBOTools.jl/formats/bqpjson.md)   |   ✅   |   ✅   |   ✅   |     ✅     |   ❌   |    ✅     |
| [MiniZinc](https://juliaqubo.github.com/QUBOTools.jl/formats/minizinc.md) |   ❌   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |
|   [QUBin](https://juliaqubo.github.com/QUBOTools.jl/formats/qubin.md)     |   ✅   |   ✅   |   ✅   |     ✅     |   ✅   |    ✅     |
|  [Qubist](https://juliaqubo.github.com/QUBOTools.jl/formats/qubist.md)    |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ❌     |
|    [QUBO](https://juliaqubo.github.com/QUBOTools.jl/formats/qubo.md)      |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |
|    [Rudy](https://juliaqubo.github.com/QUBOTools.jl/formats/rudy.md)      |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |

---

<div align="center">
    <a href="https://github.com/JuliaQUBO/QUBO.jl">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/JuliaQUBO/QUBO.jl/refs/heads/master/docs/src/assets/logo-collaboration-dark.png">
      <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/JuliaQUBO/QUBO.jl/refs/heads/master/docs/src/assets/logo-collaboration-light.png">
      <img alt="QUBO.jl Collaboration" src="">
    </picture> 
    </a>
</div>
