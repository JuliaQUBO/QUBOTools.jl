# Analysis

## Visualization

```@example plots
using Plots
using QUBOTools

S = SampleSet([
    Sample([0, 0], 0.5,  8),
    Sample([0, 1], 1.2, 10),
    Sample([1, 0], 1.8, 12),
    Sample([1, 1], 1.5,  4),
])

plot(S)
```

## Benchmarking

### Timing
```@docs
QUBOTools.total_time
QUBOTools.effective_time
```

### Solution Quality
```@docs
QUBOTools.success_rate
```

### Time-to-Solution (TTS)
```@docs
QUBOTools.tts
```