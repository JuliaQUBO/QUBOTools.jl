# Manual

## Introduction

This manual aims to explain the fundamental concepts behind loading, manipulating and analyzing models with QUBOTools.

## Quick Start Guide

```@example quick-start
using JuMP
using ToQUBO
using DWaveNeal # <- Your favourite Annealer/Sampler/Solver here

model = Model(() -> ToQUBO.Optimizer(DWaveNeal.Optimizer))

@variable(model, x[1:3], Bin)
@objective(model, Max, 1.0 * x[1] + 2.0 * x[2] + 3.0 * x[3])
@constraint(model, 0.3 * x[1] + 0.5 * x[2] + 1.0 * x[3] <= 1.6)

optimize!(model)

solution_summary(model)
```

## Table of Contents
```@contents
Pages = ["2-model.md", "3-usage.md", "4-models.md", "5-formats", "6-solutions.md", "7-analysis.md"]
Depth = 2
```
