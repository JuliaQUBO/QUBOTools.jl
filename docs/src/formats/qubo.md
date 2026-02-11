# QUBO

## Format

```@docs
QUBOTools.qubo_fmt
```

## Generating QUBO Files

```julia
using QUBOTools

# Create a model
model = QUBOTools.Model{Int,Float64,Int}(
    Dict{Int,Float64}(1 => 0.0, 3 => 0.4, 5 => -4.4),
    Dict{Tuple{Int,Int},Float64}((1, 3) => -0.8, (1, 5) => 6.0);
    scale = 2.7,
    offset = 1.93,
    domain = :bool,
    metadata = Dict("id" => 2, "description" => "Model 2 ~ Simple model with solutions")
)

# Write using D-Wave style (default)
QUBOTools.write_model("output.qubo", model, QUBOTools.Format{:qubo}(style=:dwave))

# Or write using MQLib style
QUBOTools.write_model("output.qubo", model, QUBOTools.Format{:qubo}(style=:mqlib))
```

## Example Output (D-Wave Style)

```text
c scale : 2.7
c offset : 1.93
c id : 2
c description : "Model 2 ~ Simple model with solutions"
p qubo 0 3 2 2
c linear terms
1 1 0.4
2 2 -4.4
c quadratic terms
0 1 -0.8
0 2 6.0
```

## References

- [D-Wave qbsolv](https://github.com/dwavesystems/qbsolv)
