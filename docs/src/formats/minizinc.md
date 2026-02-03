# MiniZinc

## Format

```@docs
QUBOTools.minizinc_fmt
```

## Generating MiniZinc Files

```julia
using QUBOTools

# Create a model
model = QUBOTools.Model{Int,Float64,Int}(
    Dict{Int,Float64}(2 => 1.3, 6 => -0.7),
    Dict{Tuple{Int,Int},Float64}();
    scale = 1.0,
    offset = 0.0,
    sense = :min,
    domain = :bool,
    metadata = Dict("id" => 1, "description" => "Model 1 ~ Simple model with linear terms")
)

# Write to file
QUBOTools.write_model("output.mzn", model)
```

## Example Output

```text
% id : 1
% description : "Model 1 ~ Simple model with linear terms"
set of int: Domain = {0,1};
var Domain: x1;
var Domain: x2;
float: scale = 1.0;
float: offset = 0.0;
var float: objective = scale * (1.3*x1 + -0.7*x2 + offset);
solve minimize objective;
```