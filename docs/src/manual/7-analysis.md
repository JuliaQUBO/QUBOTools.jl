# Analysis

## Models

```@setup analysis
using Random

Random.seed!(0)

const render_visualization = let
    try
        @eval import Plots
        obj -> Plots.plot(obj)
    catch err
        bt = catch_backtrace()
        msg = sprint(io -> showerror(io, err, bt))

        if Sys.iswindows() && occursin("libGRM", msg)
            @info "Plots could not initialize on this Windows runner; showing the recipe object instead." exception = (err, bt)
            identity
        else
            rethrow()
        end
    end
end

nothing
```

```@example analysis
using QUBOTools

n = 8

# Generates a Sherrington-Kirpatrick model
model = QUBOTools.generate(QUBOTools.SK(n))
```

### Model Density

```@example analysis
render_visualization(QUBOTools.ModelDensityPlot(model))
```

### System Layout

```@example analysis
render_visualization(QUBOTools.SystemLayoutPlot(model))
```

## Solutions

```@setup analysis
function magical_solution_method(model, k = 30)
    n = QUBOTools.dimension(model)

    samples = Sample{Float64,Int}[]

    for _ = 1:k
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
λ = minimum(QUBOTools.value, solution) # threshold

render_visualization(QUBOTools.EnergyFrequencyPlot(solution, λ))
```

### Energy Distribution

```@example analysis
render_visualization(QUBOTools.EnergyDistributionPlot(solution))
```
