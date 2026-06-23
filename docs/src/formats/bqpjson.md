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

Generated models can record provenance under `metadata.synthesis`. The schema
requires a `model` string and a `parameters` object. Wishart-generated models
use `model = "Wishart"` and integer `n` and `m` parameters:

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

## References

- [BQPJSON Documentation](https://bqpjson.readthedocs.io)
- [BQPJSON Repository (LANL-ANSI)](https://github.com/lanl-ansi/bqpjson)
