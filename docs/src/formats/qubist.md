# Qubist

## Format

```@docs
QUBOTools.qubist_fmt
```

## Generating Qubist Files

```julia
using QUBOTools

# Create a model (Qubist format is for spin domain)
model = QUBOTools.Model{Int,Float64,Int}(
    Dict{Int,Float64}(1 => 0.75, 2 => -3.0, 3 => 1.25),
    Dict{Tuple{Int,Int},Float64}((1, 2) => 1.0, (1, 3) => 1.0, (2, 3) => 1.0);
    domain = :spin
)

# Write to file
QUBOTools.write_model("output.spin.qh", model)
```

## Example Output

```text
3 6
1 1 0.75
2 2 -3.0
3 3 1.25
1 2 1.0
1 3 1.0
2 3 1.0
```

## References

- [dwig (D-Wave Instance Generator)](https://github.com/lanl-ansi/dwig)
