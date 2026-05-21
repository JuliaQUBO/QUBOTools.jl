# QUBOTools.jl Changelog

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
