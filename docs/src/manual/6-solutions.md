# Solutions

A solution, as defined by the [`QUBOTools.AbstractSolution`](@ref) interface, is an ordered set of samples.

## Sample records

A solution instance should contain an array of samples, where each sample is a 3-tuple ``(\psi, \lambda, r)``.
Moreover, ``\psi \in \mathbb{U}^{n} \sim \mathbb{B}^{n}`` is the sampled vector, ``\lambda \in \mathbb{R}`` is the associated energy value and ``r \in \mathbb{N}`` is the number of reads, i. e., the multiplicity of the sample.
Samples should be sorted by increasing values of ``\lambda``, then by decreasing the number of reads, and lastly by increasing the lexicographic order of their state vectors.

## Reference Implementation

Optimization results and metadata are stored in a specialized data structre, the [`QUBOTools.SampleSet`](@ref).

## Metadata

The solution metadata should be stored in a JSON-compatible associative map with string keys, such as `Dict{String,Any}`.

### Timing

We define two different time measures to evaluate the solution methods, namely the *total time* and the *effective time*.
The `"time"` entry in the solution metadata dictionary is reserved and should be used solely to store the values of these measurements.
When present, it must be itself a dictionary with positive numeric values.

#### Total Time

This measurement accounts for the complete sampling period, including: data manipulation, connection with the solver, problem embedding, solution post-processing, and other related tasks.
The `"total"` entry in the `"time"` dictionary is reserved for it.

#### Effective Time

Aimed at recording the time spent exclusively by the solving method, e.g., the actual usage of a Quantum Processing Unit (QPU).
It will be stored in the the `"effective"` entry in the `"time"` dictionary.

#### Other Measurements

Solution platforms will commonly provide additional timing information with varying levels of granularity.
Besides the `"total"` and `"effective"` keys, other fields can be used for solver-specific data without major caveats.

For validation purposes, it is required that the total time is bigger than all other values stored.
Since different time records might intersect, there are no restrictions regarding the sum of those.

### Origin

When used, the `"origin"` field is a string referring to the method used for solving the problem, which could be the name of a cloud platform or even hardware identification details.
