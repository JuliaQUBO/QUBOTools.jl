# Analysis

## Problems
```@example problem-analysis
using QUBOTools: Model
```

## Solutions

### Visualization

```@example problem-analysis
using Plots

L = Dict{Int,Float64}(1 => 0.5, 2 => 2.0, 3 => -3.0)
Q = Dict{Tuple{Int,Int},Float64}((1,2) => 2.0, (1,3) => -2.0, (2,3) => 0.5)

m = Model{Int,Float64,Int}(L, Q; domain=:bool)

QUBOTools.ModelDensityPlot(m) |> plot
```

```@example solution-plots
using Plots
using QUBOTools

s = SampleSet([
    Sample([0, 0], 0.5,  8),
    Sample([0, 1], 1.2, 10),
    Sample([1, 0], 1.8, 12),
    Sample([1, 1], 1.5,  4),
])

λ = 0.5 # ground state

QUBOTools.EnergyFrequencyPlot(s, λ) |> plot
```