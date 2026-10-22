# BQPJSON

## Format

```@docs
QUBOTools.bqpjson_fmt
```

## Generating BQPJSON Files

```julia
using QUBOTools

# Create a model
model = QUBOTools.Model{Int,Float64,Int}(
    Dict{Int,Float64}(1 => 0.0, 3 => 0.4, 5 => -4.4),
    Dict{Tuple{Int,Int},Float64}((1, 3) => -0.8, (1, 5) => 6.0);
    scale = 2.7,
    offset = 1.93,
    domain = :bool,
    metadata = Dict("id" => 2, "description" => "Simple QUBO Problem")
)

# Write to file
QUBOTools.write_model("output.bool.json", model)
```

## Example Output

```json
{
  "linear_terms": [
    {
      "id": 2,
      "coeff": 0.4
    },
    {
      "id": 3,
      "coeff": -4.4
    }
  ],
  "variable_domain": "boolean",
  "offset": 1.93,
  "id": 2,
  "variable_ids": [
    1,
    2,
    3
  ],
  "quadratic_terms": [
    {
      "id_head": 1,
      "coeff": -0.8,
      "id_tail": 2
    },
    {
      "id_head": 1,
      "coeff": 6.0,
      "id_tail": 3
    }
  ],
  "metadata": {},
  "scale": 2.7,
  "version": "1.0.0",
  "description": "Simple QUBO Problem"
}

```

## Synthesis Metadata

Generated models can record provenance under `metadata.synthesis`. The generic
schema requires a `model` string and a `parameters` object. For non-Wishart
generators, `model` can be any string other than `"Wishart"` and `parameters`
can contain generator-specific fields.

Wishart-generated models use `model = "Wishart"` and integer `n` and `m`
parameters:

```json
{
  "metadata": {
    "synthesis": {
      "model": "Wishart",
      "parameters": {
        "n": 100,
        "m": 10
      }
    }
  }
}
```

## Interchange Notes

- **Variable mapping**: `write_model` exports 1-based integer `variable_ids` (`indices(model) = 1:n`). To restore non-consecutive, permuted, or non-integer variable labels after `read_model`, apply `QUBOTools.map_variables(variables(src_model), dst_model)`.
- **Sense canonicalization**: BQPJSON v1.0.0 represents minimization problems (`sense = :min`). When exporting a `:max` model, `write_model` negates linear and quadratic coefficients, `offset`, and sample `evaluation`s so optimal assignments and rankings are preserved; restore `:max` sense on import with `QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), dst_model)`.
- **Sample multiplicities**: `SampleSet` entries with `reads > 1` are expanded into repeated `solutions` entries with distinct `id`s on write and merged back into aggregated `reads` counts on read. Solution-level `metadata` is not part of the BQPJSON v1.0.0 schema.
- **Numeric conversion**: `read_model` parses coefficients, `scale`, `offset`, and sample `evaluation`s as `Float64` (`Model{Int,Float64,Int}`). Values outside exact IEEE 754 `Float64` representation (such as integers with `|c| > 2^53` or `BigFloat` values) are rounded to `Float64`.

## References

- [BQPJSON Documentation](https://bqpjson.readthedocs.io)
- [BQPJSON Repository (LANL-ANSI)](https://github.com/lanl-ansi/bqpjson)
