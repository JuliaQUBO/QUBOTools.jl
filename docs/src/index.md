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

## Citing QUBOTools.jl
<!-- citation-policy:start -->
For general use of `QUBOTools.jl` and the broader `QUBO.jl` ecosystem, cite the
[published journal article](https://doi.org/10.1080/10556788.2026.2702926). The
earlier [arXiv preprint](https://arxiv.org/abs/2307.02577) remains available,
but the journal article is the version of record.

For a direct software citation, use the
[Zenodo concept DOI](https://doi.org/10.5281/zenodo.7076341). The concept DOI
is the evergreen identifier for `QUBOTools.jl`, resolves to the latest archived
release, and is the DOI recorded in `CITATION.cff`. When reproducibility
requires an exact release, cite the matching Zenodo version DOI instead; the
archive for `v0.16.2` is
[10.5281/zenodo.23218355](https://doi.org/10.5281/zenodo.23218355).

The BibTeX entries below cite the ecosystem article and the `v0.16.2` software
archive. Replace the `@software` entry's `doi` and `url` with the concept DOI
when an evergreen software citation is preferred:

```bibtex
@article{xavier2026qubojl,
  author       = {Maciel Xavier, Pedro and Ripper, Pedro and Andrade, Tiago and Dias Garcia, Joaquim and Maculan, Nelson and Bernal Neira, David E.},
  title        = {{QUBO.jl: a Julia ecosystem for quadratic unconstrained binary optimization}},
  journal      = {Optimization Methods and Software},
  year         = {2026},
  pages        = {1--24},
  doi          = {10.1080/10556788.2026.2702926},
  url          = {https://doi.org/10.1080/10556788.2026.2702926}
}

@software{qubotools:2026,
  author       = {Maciel Xavier, Pedro and Ripper, Pedro and Andrade, Tiago and Dias Garcia, Joaquim and Bernal Neira, David E.},
  title        = {{QUBOTools.jl}},
  year         = {2026},
  publisher    = {Zenodo},
  version      = {v0.16.2},
  doi          = {10.5281/zenodo.23218355},
  url          = {https://doi.org/10.5281/zenodo.23218355},
  note         = {Evergreen concept DOI: 10.5281/zenodo.7076341}
}
```

Machine-readable metadata is in
[`CITATION.cff`](https://github.com/JuliaQUBO/QUBOTools.jl/blob/main/CITATION.cff),
with BibTeX in
[`CITATION.bib`](https://github.com/JuliaQUBO/QUBOTools.jl/blob/main/CITATION.bib).
<!-- citation-policy:end -->