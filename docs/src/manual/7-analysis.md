# Analysis

## Models

```@setup analysis
using Random

Random.seed!(0)
```

```@example analysis
using QUBOTools

n = 8

# Generates a Sherrington-Kirpatrick model
model = QUBOTools.generate(QUBOTools.SK(n))
```

### Model Density

```@example analysis
using Plots

plot(QUBOTools.ModelDensityPlot(model))
```

### System Layout

```@example analysis
plot(QUBOTools.SystemLayoutPlot(model))
```

## Solutions

```@example analysis
samples = Sample{Float64,Int}[]

for i = 1:5
    ψ = rand(0:1, n)
    λ = QUBOTools.value(model, ψ)
    r = rand(1:10)

    push!(samples, Sample(ψ, λ, r))
end

solution = SampleSet(samples)
```

### Energy Frequency

```@example analysis
λ = -100.0 # threshold

plot(QUBOTools.EnergyFrequencyPlot(solution, λ))
```
