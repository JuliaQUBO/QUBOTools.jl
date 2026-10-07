# Models

This package defines [`QUBOTools.AbstractModel`](@ref) as an abstract type for QUBO models.
`V` is a type for representing variables, usually an integer or string-like type.
The problem's coefficients are stored under the `T` type, that also represents the energy values corresponding to each solution.
When solution state vectors are sampled, their entries will be of the integer type `U`.
Since values are binary, using integer types smaller than `Int64` is a reasonable choice.

## Reference Implementation

QUBOTools also exports the [`QUBOTools.Model`](@ref) type, designed to work as standard backend for other applications to be built atop.

## [Conditioning variables and reconstructing states](@id variable-conditioning)

Use [`QUBOTools.fix_variables`](@ref) on a model's form to fix variables to a
specified boundary state. It returns `(reduced, offset_delta, index_map)`.
The map runs from **original form index to reduced form index**, retaining the
original order of free variables, including isolated variables. Model labels
are a separate mapping: translate labels with [`QUBOTools.index`](@ref), and
recover them with [`QUBOTools.variable`](@ref).

If the original energy is
```math
E(x) = \alpha\left(\beta + \sum_i L_i x_i + \sum_{i<j} Q_{ij}x_i x_j\right),
```
conditioning substitutes each fixed value into this expression. A crossing term
contributes to the free variable's linear coefficient; terms with only fixed
variables contribute to the constant. The reduced form preserves storage types,
scale ``\alpha``, domain, and objective sense, for both minimization and
maximization. With `x = QUBOTools.lift_state(y, fix, index_map, n)`, its exact
algebraic contract is
```math
E(x) = E_{\mathrm{reduced}}(y).
```
Floating-point evaluation may differ by roundoff. `offset_delta` is **unscaled**,
and the reduced offset already equals `QUBOTools.offset(original) + offset_delta`.
Do not add `offset_delta` or `scale * offset_delta` again when evaluating the
reduced form.

This runnable example uses reordered labels, an isolated variable `:unused`,
scale 2 and offset 5. Its energy is
``2(5 - 3x_1 + 2x_2 - x_3 + 4x_1x_2 - 2x_2x_3)``.

```@example conditioning
using QUBOTools, SparseArrays

labels = [:z, :a, :middle, :unused]
model = QUBOTools.Model{Symbol,Float64,Int}(
    labels,
    sparsevec([1, 2, 3], [-3.0, 2.0, -1.0], 4),
    sparse([1, 2], [2, 3], [4.0, -2.0], 4, 4);
    scale = 2.0, offset = 5.0, sense = :max, domain = :bool,
)
original = QUBOTools.form(model)
fixed_labels = Dict(:a => 1)
fix = Dict(QUBOTools.index(model, label) => v for (label, v) in fixed_labels)
reduced, offset_delta, index_map = QUBOTools.fix_variables(original, fix)
@assert index_map == Dict(1 => 1, 3 => 2, 4 => 3)
@assert offset_delta == 2.0
@assert QUBOTools.offset(reduced) == 7.0

label_to_reduced = Dict(QUBOTools.variable(model, i) => j for (i, j) in index_map)
candidate = Dict(:unused => 1, :middle => 0, :z => 1)
y = Vector{Int}(undef, QUBOTools.dimension(reduced))
for (label, j) in label_to_reduced
    y[j] = candidate[label]
end
x = QUBOTools.lift_state(y, fix, index_map, QUBOTools.dimension(original))
full_labels = Dict(QUBOTools.variable(model, i) => x[i] for i in eachindex(x))
@assert full_labels == merge(candidate, fixed_labels)
@assert QUBOTools.value(model, x) == QUBOTools.value(y, reduced) == 16.0
full_labels
```

For binary ``x_2=1``, direct substitution gives ``2(7 + x_1 - 3x_3)``.
For the same coefficients in the spin domain with ``x_2=-1``, it gives
``2(3 - 7x_1 + x_3)``. The isolated fourth variable remains part of the
state in either domain, even though it does not affect energy.

Fixed indices must lie in `1:n`. Binary fixed values must be in ``\{0,1\}``;
spin fixed values must be in ``\{-1,1\}``. Invalid indices or fixed values
throw `ArgumentError`. An empty fixed dictionary leaves every variable free.
Fixing every variable yields a zero-dimensional form, whose empty state has
the full fixed-state energy; a form that starts empty also retains its constant.
`lift_state` validates lengths and that fixed indices and the bijective index
map cover `1:n`; it has no domain argument and does not validate state values.
Use the same validated fixed dictionary and a valid reduced state.

### Zero boundaries and consumer policy

Removing interactions that cross a selected binary subset has the exact
zero-boundary interpretation: fixing all omitted variables to zero makes those
interactions vanish, along with omitted linear and fixed-only terms. Retain the
original offset to preserve the energy identity. For spin variables, zero is
outside the domain, so dropping crossing terms cannot represent a valid zero
boundary. Choosing an induced approximation and accounting for its effect is
a consumer policy.

Decomposition plans, selection strategies, budgets, incumbent management,
aggregation and repair belong in the standalone decomposition package.
Algorithm-specific adjacency indices and plan schemas stay there as well.
Promote a future specialized primitive to QUBOTools only when demonstrated
reuse or stable general semantics with measured benefit justify it, accompanied
by correctness and performance evidence. Optimize sparse construction only
after representative profiling establishes a material cost and a focused
change is justified.

## Model Backend

```@example model-backend
using QUBOTools

mutable struct SuperModel{V,T,U} <: QUBOTools.AbstractModel{V,T,U}
    model::QUBOTools.Model{V,T,U}
    super::Bool

    function SuperModel{V,T,U}() where {V,T,U}
        return new(QUBOTools.Model{V,T,U}(), true)
    end
end

QUBOTools.backend(model::SuperModel) = model.model
```

```@example model-backend
model = SuperModel{Symbol,Float64,Int}()
```

## JuMP Integration

One of the main milestones was to make [JuMP](https://jump.dev) / [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl) integration easy.
When `V` is set to `MOI.VariableIndex` and `T` matches `Optimzer{T}`, the QUBOTools backend is able to handle most of the data management workload.
