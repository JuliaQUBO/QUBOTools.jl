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

```@setup analysis
function magical_solution_method(model)
    n = QUBOTools.dimension(model)

    samples = Sample{Float64,Int}[]

    for _ = 1:5
        ψ = rand(0:1, n)
        λ = QUBOTools.value(model, ψ)
        r = rand(1:10)

        push!(samples, Sample(ψ, λ, r))
    end

    return SampleSet(samples)
end
```

```@example analysis
solution = magical_solution_method(model)
```

### Energy Frequency

```@example analysis
λ = minimum(QUBOTools.value.(solution)) - 1.0 # threshold

plot(QUBOTools.EnergyFrequencyPlot(solution, λ))
```
