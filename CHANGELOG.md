# QUBOTools.jl Changelog

## v0.15.1 (2026-06-24)

### Compatibility

- Allow PseudoBooleanOptimization 0.3 releases.

## v0.15.0 (2026-06-24)

### Breaking Changes

- Tighten BQPJSON validation for `metadata.synthesis`: files with this key must
  now use a synthesis object with a `model` string and `parameters` object, with
  Wishart metadata requiring integer `n` and `m` parameters.

## v0.14.4 (2026-06-21)

### CI

- Treat downstream QUBOTools compatibility resolver failures in foreign package tests as expected broken tests, including ANSI-colored resolver messages from CI logs.

## v0.14.3 (2026-06-21)

### Performance

- Speed up MOI backend extraction for compact variable indices while preserving sparse or non-positive variable-index fallbacks.

### Documentation

- Document direct reproduction of the larger MOI backend extraction benchmark shape.

### Testing

- Add regression coverage for MOI variable-index lookup fallbacks and sparse remaining variable IDs.

### CI

- Allow TagBot to comment on registration issues by granting write access to issues.

## v0.14.2 (2026-06-18)

### CI

- Report foreign package tests as known incompatible when a downstream package explicitly excludes the current QUBOTools minor series.

## v0.14.1 (2026-06-18)

### CI

- Allow the documentation and benchmark environments to develop QUBOTools 0.14.x.

## v0.14.0 (2026-06-18)

### Features

- Add Rudy format inference and write/read round-trip support.

### Performance

- Build sparse linear and quadratic forms directly with sparse storage instead of dense intermediates.

### Bug Fixes

- Parse scientific-notation coefficients in QUBO and Rudy files.
- Fix the generator deprecation warning spelling.

### Documentation

- Add a scalability manual page documenting the opt-in scale-test tier and practical sparse/dense size envelope.

### Testing

- Add an opt-in scale-test tier, with scheduled CI coverage for generated sparse cases up to 100000 variables.
- Add regression coverage for QUBO and Rudy scientific-notation round trips and the generator deprecation warning.

## v0.13.1 (2026-06-13)

### Breaking Changes

- Replace the unusable `fix_variables(fix, form)` stub with `fix_variables(form, fix::AbstractDict)`, requiring fixed variable values and returning the reduced form, raw offset delta, and old-to-new index map.

### Features

- Add `lift_state` for reconstructing full states from variable-fixing reductions.

### Performance

- Speed up MOI backend extraction by building sparse forms directly from MOI objective terms instead of first materializing large intermediate dictionaries.

### Documentation

- Document `QUBOTools.Model(moi_model)` as the supported public MOI/ToQUBO materialization path.

### Testing

- Add dense TSP-style backend extraction benchmark coverage, including an opt-in 10,000-variable scale case.
- Add regression coverage for variable-fixing reductions and lifted states.

### CI

- Cache documentation build dependencies in the benchmark docs workflow.

## v0.12.1 (2026-05-28)

### Compatibility

- Allow GeometryBasics 0.5 so downstream packages can resolve newer SciML stacks alongside QUBOTools.

### Documentation

- Update the manual introduction link to the canonical JuliaQUBO repository.

## v0.12.0 (2026-05-21)

### Breaking Changes

- Require Julia 1.10 or newer.

### Documentation

- Configure Documenter with an explicit QUBOTools GitHub remote and `main` edit links.
- Keep generated documentation links from falling back to `master` when local git remote inference is unavailable.

### Testing

- Add documentation integration assertions for generated edit links.

## v0.11.1 (2026-05-21)

### Testing

- Fix test helper compatibility with Julia 1.9.
- Remove unnecessary `Plots` dependency from the test environment.
- Keep documentation examples covered in package tests without requiring plot rendering there.

### CI

- Test the advertised Julia floor and latest stable Julia in CI.
- Run documentation and benchmark workflows on latest stable Julia.

## v0.11.0 (2026-04-07)

### Breaking Changes

- **Unified format type system**: All concrete format types (`BQPJSON`, `MiniZinc`, `Qubist`, `QUBO`, `QUBin`, `Rudy`) replaced by parametric `Format{:symbol}` types (e.g., `Format{:bqpjson}`). Code that dispatches on the old struct names must be updated.
- **`format()` renamed to `infer_format()`**: The `format(path)` and `format(hints...)` functions for inferring file format are now `infer_format(; path)` and `infer_format(hints)`.
- **Removed `style()` function**: `style(::AbstractFormat)` has been removed.
- **Removed `__moi_qubo_model()`**: The internal helper for exporting `QUBOModel` from the MOI extension has been removed.
- **`QUBOModel` now supports fixed variables**: `QUBOModel{T,C}` has a new `fixed::Dict{VI,T}` field. The MOI model parser now handles `MOI.EqualTo` constraints for variable fixing, changing the signatures of `_extract_bool_model` and `_extract_spin_model`.
- **`MOI.get(model, ListOfVariableIndices())` now returns a copy**: Previously returned the internal vector directly.

### Performance

- Speed up sparse model construction with new `_build_sparse_forms()` helper using preallocated vectors and `dropzeros!()`.

### Bug Fixes

- Fix sparse array dimensions in QUBin (HDF5) parser by adding `n` parameter for proper sparse reconstruction.
- Fix QUBin solution data parsing and `SampleSet` reconstruction.
- Fix QUBin metadata JSON deserialization.
- Fix BQPJSON domain validation to use correct variable name (`x` instead of `s` for spin).

### Testing

- Add comprehensive form conversion tests covering sense/domain casting, topology validation, and dict/sparse constructors.
- Add benchmark suite for model constructors with parametric fixtures.
- Clarify MOI benchmark coverage.

### Documentation

- Skip docs plot rendering on Windows CI to avoid intermittent GR artifact failures.
- Fix broken README badge links (`github.com` → `github.io`), footer branch refs, and Zenodo DOI badge.
- Add `qubist` URL reference and examples in format docs.

### CI

- Add benchmark workflow that runs on PRs and compares against `origin/main`.
- Add label automation workflows (sync, backfill, PR labeler, validation).
- Update codecov action to v5.
- Upgrade deprecated GitHub Actions.
- Pin action SHAs and validate workflow labels via `pyyaml`.

## v0.10.1 (2024-10-02)

- Previous release.
