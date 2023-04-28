# Analysis

## Problems

## Solutions

### Visualization

```@example plots
using Plots
using QUBOTools

s = SampleSet([
    Sample([0, 0], 0.5,  8),
    Sample([0, 1], 1.2, 10),
    Sample([1, 0], 1.8, 12),
    Sample([1, 1], 1.5,  4),
])

plot(s)
```