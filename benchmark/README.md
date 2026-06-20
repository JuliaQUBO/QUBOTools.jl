# Benchmark

This benchmark suite compares the current development checkout against the
repository `main` branch.

Run the full comparison from the repository root with:

```bash
git fetch origin main
julia --project=benchmark benchmark/benchmark.jl --run --main
julia --project=benchmark benchmark/benchmark.jl --run --dev
julia --project=benchmark benchmark/report.jl --run
```

The benchmark runner stores tuning parameters and benchmark results under
`benchmark/data/`, and the report script writes `benchmark/data/REPORT.md`.
The report compares `main` and `dev` using minimum-time estimates with a 15%
tolerance to keep CI noise from showing up as false regressions. The reported
times cover batched benchmark operations, so they should be read as relative
comparison figures rather than per-call timings.

The constructors suite includes both dict-backed model construction and direct
boolean `MOI.ModelLike` parsing through `QUBOTools.Model(moi_model)` so that
performance work such as issue `#56` is exercised by the benchmark harness on
the reported QUBO conversion path.

It also includes a dense TSP-style constructor fixture (`tsp/cities=36`) that
exercises the same public MOI extraction path used by ToQUBO integrations:

```julia
QUBOTools.Model(moi_model)
```

Profiling this path should be interpreted as QUBOTools backend
materialization, not JuMP model construction or optimization. For dense TSP
fixtures the dominant work is linear in the number of MOI quadratic terms:
copying MOI terms into sparse triplet buffers, then converting those buffers to
the package sparse CSC representation with `SparseArrays.sparse`.

To reproduce the larger 10,000-variable extraction shape directly, run:

```bash
julia --project=benchmark -e '
import Pkg
Pkg.develop(; path = pwd())
Pkg.instantiate()

using Random
using SparseArrays
using BenchmarkTools
using MathOptInterface
using QUBOTools

include("benchmark/suites/fixtures.jl")

fixture = benchmark_dense_tsp_constructor_fixture("tsp/cities=100", 100)

display(@benchmark QUBOTools.Model($(fixture.bool_moi_model)) samples = 10 evals = 1)
'
```

The default fixture is sized for pull-request benchmark runtime. To add the
10,000-variable TSP extraction case (`tsp/cities=100`) to the constructor suite,
set `QUBOTOOLS_SCALE_BENCHMARKS=true` when running the benchmark commands.

To smoke-test the benchmark harness itself without running the full benchmark,
use:

```bash
julia --project=benchmark benchmark/test/runtests.jl
```
