# Analysis

## Models

```@setup analysis
using Random

Random.seed!(0)

const render_visualization = let
    # GitHub's Windows runner intermittently fails to load GR artifacts.
    # Keep the examples executable there by rendering the recipe object instead.
    if get(ENV, "QUBOTOOLS_DOCS_SKIP_PLOTS", "false") == "true" ||
       (Sys.iswindows() && get(ENV, "CI", "false") == "true")
        @info "Skipping plot rendering; showing the recipe object instead."
        identity
    else
        @eval import Plots
        obj -> Plots.plot(obj)
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

## Time-to-Target and Trial Semantics

Time-to-target (TTT) estimates require the probability unit and the time unit to match, and must distinguish a known IID trial probability from an empirical `successes / trials` estimate over a finite sample count.

### Independent Reads vs. Independent Runs

When a sampler records the duration of a batch of $R$ independent reads (such as `RandomSampler`), declare `trial_unit = :read` so each read receives $t_{\text{trial}} = t_{\text{batch}} / R$:

```@example analysis
read_batch = SampleSet(
    [
        Sample([0, 0, 1], 1.0, 1),
        Sample([0, 1, 0], 2.0, 2),
        Sample([0, 1, 1], 3.0, 3),
        Sample([1, 0, 0], 4.0, 4),
    ];
    metadata = Dict{String,Any}(
        "time" => Dict{String,Any}("effective" => 1.0, "total" => 2.0),
    ),
    sense = :min,
    domain = :bool,
)

read_est = QUBOTools.time_to_target_estimate(read_batch, 1.0; trial_unit = :read)
(
    trial_unit = read_est.trial_unit,
    trials = read_est.trials,
    successes = read_est.successes,
    trial_time = read_est.trial_time,
    operational_ttt = read_est.operational_ttt,
    continuous_ttt = read_est.continuous_ttt,
)
```

When a `SampleSet` represents a single solver run (or a trajectory/selected batch), declare `trial_unit = :run` (or pass a vector of independent run `SampleSet`s):

```@example analysis
run_est = QUBOTools.time_to_target_estimate(read_batch, 1.0; trial_unit = :run)
(
    trial_unit = run_est.trial_unit,
    trials = run_est.trials,
    successes = run_est.successes,
    trial_time = run_est.trial_time,
    status = run_est.status,
)
```

### Cost Boundaries and Endpoint Semantics

- **Named cost boundaries**: Select `cost_boundary = :effective` (backend `metadata["time"]["effective"]`), `cost_boundary = :total` (solver wall time `metadata["time"]["total"]`), or `cost_boundary = :complete` (caller-supplied complete trial/batch cost or `metadata["time"]["complete"]`). Boundaries are never silently substituted for one another.
- **Known vs. empirical endpoints**:
  - For a known trial probability $p = 1$ and $0 < s < 1$, one trial is still required (`operational_ttt == trial_time`, `status == :known_unit_probability`); known $p = 0$ is unattainable (`Inf`, `status == :known_zero_probability`).
  - Empirical all-success (`N/N`) and all-failure (`0/N`) batches retain their finite `trials = N` and `successes` counts with `status == :empirical_all_succeeded` or `:empirical_zero_successes` rather than claiming certified certainty or impossibility.
- **Non-IID sample regimes and migration**: Solutions tagged with `"sampling_regime"` (or `"trial_semantics"` / `"sample_selection"`) in `("correlated", "selected", "repaired", "best_only", "postselected", "top_k")` reject `trial_unit = :read`. Legacy calls `time_to_target(sol, λ, s)` without `trial_unit` emit a deprecation warning; migrate by passing `trial_unit = :read` or `trial_unit = :run` (or calling [`QUBOTools.time_to_target_estimate`](@ref)).
