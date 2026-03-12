# QUBin

## Format

```@docs
QUBOTools.qubin_fmt
```

## Generating QUBin Files

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

# Write to HDF5 file
QUBOTools.write_model("output.bool.qb", model)
```

## Structure

Below, an outline of the HDF5 file layout that QUBin files follow:

```text
🗂️ HDF5.File: (read-only) test/data/02/bool.qb
├─ 📂 model                           # Problem formulation
│  ├─ 📂 form                         # Mathematical form (sparse representation)
│  │  ├─ 🔢 dimension                 # Number of variables
│  │  ├─ 🔢 domain                    # Variable domain ("bool" or "spin")
│  │  ├─ 📂 linear                    # Linear terms
│  │  │  ├─ 🔢 i                      # Variable indices
│  │  │  └─ 🔢 v                      # Coefficient values
│  │  ├─ 🔢 offset                    # Constant offset β
│  │  ├─ 📂 quadratic                 # Quadratic terms
│  │  │  ├─ 🔢 i                      # First variable indices
│  │  │  ├─ 🔢 j                      # Second variable indices
│  │  │  └─ 🔢 v                      # Coefficient values
│  │  ├─ 🔢 scale                     # Scaling factor α
│  │  └─ 🔢 sense                     # Optimization sense ("min" or "max")
│  ├─ 🔢 metadata                     # JSON-encoded problem metadata
│  └─ 🔢 variables                    # Variable name/ID mapping
└─ 📂 solution                        # Solution data
   ├─ 📂 data                         # Solution samples
   │  ├─ 🔢 reads                     # Number of occurrences for each sample
   │  ├─ 🔢 state                     # Variable assignments (matrix: vars × samples)
   │  └─ 🔢 value                     # Objective function values
   ├─ 🔢 domain                       # Solution domain ("bool" or "spin")
   ├─ 🔢 metadata                     # JSON-encoded solution metadata
   └─ 🔢 sense                        # Solution sense ("min" or "max")
```
