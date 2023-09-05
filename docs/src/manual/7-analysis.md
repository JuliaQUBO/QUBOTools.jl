# Analysis

## Models

```@example model-analysis
using QUBOTools

L = Dict{Int,Float64}(1 => 0.5, 2 => 2.0, 3 => -3.0)
Q = Dict{Tuple{Int,Int},Float64}((1,2) => 2.0, (1,3) => -2.0, (2,3) => 0.5)

m = QUBOTools.Model{Int,Float64,Int}(L, Q; domain=:bool, sense=:min)
```

```@example model-analysis
using Plots

p = QUBOTools.ModelDensityPlot(m)

plot(p)
```

## Solutions

```@example solution-analysis
using QUBOTools
using Plots

sol = SampleSet([
    Sample([0, 0], 0.5,  8),
    Sample([0, 1], 1.2, 10),
    Sample([1, 0], 1.8, 12),
    Sample([1, 1], 1.5,  4),
])

λ = 0.5 # ground state

p = QUBOTools.EnergyFrequencyPlot(sol, λ)

plot(p)
```
