# Manual

## Introduction

This manual aims to explain the fundamental concepts behind loading, manipulating and analyzing models with QUBOTools.

## Quick Start Guide

```@example quick-start
using QUBOTools

path = joinpath(@__DIR__, "data", "problem.json")

model = QUBOTools.read_model(path)
```

## Table of Contents

```@contents
Pages = [
    "2-model.md",
    "3-usage.md",
    "4-models.md",
    "5-formats",
    "6-solutions.md",
    "7-analysis.md"
]
Depth = 2
```
