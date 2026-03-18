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

To smoke-test the benchmark harness itself without running the full benchmark,
use:

```bash
julia --project=benchmark benchmark/test/runtests.jl
```
