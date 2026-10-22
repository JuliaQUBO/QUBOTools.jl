# File Formats

|              Format                | Read  | Write | Model | Solutions | Start | Metadata |
| :--------------------------------: | :---: | :---: | :---: | :-------: | :---: | :------: |
| [BQPJSON](../formats/bqpjson.md)   |   ✅   |   ✅   |   ✅   |     ✅     |   ❌   |    ✅     |
| [MiniZinc](../formats/minizinc.md) |   ❌   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |
|   [QUBin](../formats/qubin.md)     |   ✅   |   ✅   |   ✅   |     ✅     |   ❌   |    ✅     |
|  [Qubist](../formats/qubist.md)    |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ❌     |
|    [QUBO](../formats/qubo.md)      |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |
|    [Rudy](../formats/rudy.md)      |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |

## Portable Model and Sample Interchange

Downstream decomposition and hybrid workflows should select an interchange carrier based on which model and sample attributes must survive serialization:

| Carrier | Variable Mapping | Domains | Senses | Scale & Offset | Solutions & `reads` | Numeric & Metadata Fidelity |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **[QUBin](../formats/qubin.md)** (`.qb` / HDF5) | Exact `1:n` `Int` or `String` order preserved | `:bool`, `:spin` | `:min`, `:max` | Exact `scale` and `offset` in dataset type `T` | Full `SampleSet` (`state`, `value`, `reads`) | Preserves HDF5-native dataset types (`Float64`, `Float32`, `Int64`, etc.); JSON-encoded model/solution metadata |
| **[BQPJSON](../formats/bqpjson.md)** (`.json` v1.0.0) | Exported as `1:n` `variable_ids`; restore labels with `QUBOTools.map_variables` | `:bool`, `:spin` | Wire format is `:min`; `:max` models are negated on write and restored with [`QUBOTools.cast`](@ref) | `scale` preserved; `offset` negated when canonicalizing `:max` to `:min` | `state`, `value`, and `reads` preserved (expanded on write, merged on read) | JSON numbers parsed as `Float64` (`Model{Int,Float64,Int}`); model metadata only (schema-validated `synthesis`) |
| **Sample Tables** ([`QUBOTools.write_samples`](@ref) / [`QUBOTools.read_samples`](@ref)) | Recorded in file-level `model.variables` metadata when exported from a `Model` | `:bool`, `:spin` | `:min`, `:max` | Recorded in file-level `model` metadata when exported from a `Model` | Full `SampleSet` (`state`, `value`, `reads`) | Imported values parsed as `Float64` and `reads` as `Int` (`SampleSet{Float64,Int}`); embedded or sidecar JSON solution metadata |
| **[QUBO](../formats/qubo.md)** (`.qubo`) | Exported as `0:n-1` (`:dwave`) or `1:n` (`:mqlib`); restore with `map_variables` | `:bool` only | `:min` only | Preserved in header comments | ❌ | Parsed as `Float64`; comment metadata |
| **[Qubist](../formats/qubist.md)** (`.qh`) | Exported as `1:n`; restore with `map_variables` | `:spin` only | `:min` only | ❌ (`scale = 1.0`, `offset = 0.0`) | ❌ | Parsed as `Float64`; no metadata |
| **[Rudy](../formats/rudy.md)** (`.rudy`) | Exported as `0:n-1`; restore with `map_variables` | Configurable (`:spin` default) | `:min` only | Folded into coefficients and constant term (`scale = 1.0` on read) | ❌ | Parsed as `Float64`; `timestamp` comment only |
| **[MiniZinc](../formats/minizinc.md)** (`.mzn`) | Write-only (`x1..xn`) | `:bool`, `:spin` | `:min`, `:max` | Written as `scale` and `offset` parameters | ❌ | Write-only text; comment metadata |

### Recommended Carrier Contracts and Numeric Boundaries

1. **`QUBin` (`.qb` / HDF5)** — Use [`QUBOTools.write_model`](@ref) / [`QUBOTools.read_model`](@ref) (or [`QUBOTools.write_solution`](@ref) / [`QUBOTools.read_solution`](@ref) for standalone solutions) when full model and `SampleSet` round-trip fidelity is required:
   - Preserves non-consecutive and permuted `Int` or `String` variable orderings directly without external variable remapping.
   - Preserves HDF5-native numeric dataset element types `T` (`Float64`, `Float32`, `Int64`, `Int32`, etc.) for coefficients, `scale`, `offset`, and sample `value`s—including 64-bit integers beyond `Float64` precision such as `2^53 + 1`.
   - Non-HDF5-native numeric types (such as `BigFloat` or `Rational`) are unsupported by HDF5 dataset creation and throw a `MethodError` on write. Model and solution `metadata` dictionaries are serialized as JSON strings and therefore follow JSON type conversions.
2. **`BQPJSON` (`.json`)** — Use when JSON portability is required across tools:
   - Keep `vars = QUBOTools.variables(src_model)` (or serialize the ordered variable list alongside the workflow) and apply `dst_model = QUBOTools.map_variables(vars, QUBOTools.read_model(path))` on import so permuted or string variable labels match their original `1:n` positions.
   - If `QUBOTools.sense(src_model) === QUBOTools.Max`, `write_model` canonicalizes coefficients, `offset`, and sample `evaluation`s to `:min`; restore the original maximization sense after `read_model` via `QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), dst_model)`.
   - `read_model` always constructs a `Model{Int,Float64,Int}`. IEEE 754 `Float64` coefficients, `scale`, `offset`, and sample `evaluation`s round-trip in `Float64`, whereas integer coefficients exceeding `Float64` exact integer precision (`|c| > 2^53`, e.g. `2^53 + 1`), `Float32` values, or `BigFloat` values are converted to `Float64`.
3. **`write_samples` / `read_samples` (`.csv`)** — Use when only the sample distribution (`SampleSet`) is exchanged between subproblem solvers and aggregators:
   - Sample multiplicities (`reads`), `Float64` energies (`value`), `sense`, `domain`, `bit_order`, and JSON-compatible solution `metadata` round-trip in `SampleSet{Float64,Int}`.
   - `read_samples` always parses sample `value` cells as `Float64` (`parse(Float64, cell)`) and `reads` as `Int`, so `Float32` or `BigFloat` sample energies are converted to `Float64` on import.

## Defining a Custom File Format

```@example custom-file-format
import QUBOTools

function QUBOTools.Format{:super}(; super::Bool = true, kws...)
    settings = Dict{Symbol,Any}()

    settings[:super] = super

    return QUBOTools.Format{:super}(settings)
end
```

### Writing Models

To write a model using `SuperFormat`, one must implement the

```julia
QUBOTools.write_model(io::IO, ::QUBOTools.AbstractModel{V,T,U}, ::QUBOTools.Format{:super}) where {V,T,U}
```

method for the custom format.

!!! info
    This assumption is valid for text-based and binary formats.
    If you pretend to write in a format that does not rely on `io::IO` (such as [`QUBOTools.qubin_fmt`](@ref)),
    you should also implement

    ```julia
    QUBOTools.write_model(filepath::AbstractString, ::QUBOTools.AbstractModel{V,T,U}, ::QUBOTools.Format{:super}) where {V,T,U}
    ```

```@example custom-file-format
function QUBOTools.write_model(io::IO, model::QUBOTools.AbstractModel, fmt::QUBOTools.Format{:super})
    if fmt[:super]
        println(io, "Format Type: SUPER")

        _write_super_model(io, model)
    else
        println(io, "Format Type: Regular")

        _write_regular_model(io, model)
    end
    
    return nothing
end
```

### Reading Models

```@example custom-file-format
function QUBOTools.read_model(io::IO, fmt::QUBOTools.Format{:super})
    header = readline(io)

    if fmt[:super]
        @assert("SUPER" in header, "Invalid header: '$header' is not SUPER!")

        return _read_super_model(io)
    else
        return _read_regular_model(io)
    end
end
```

!!! info
    [`QUBOTools.read_model`](@ref) must return a [`QUBOTools.Model`](@ref) instance.
