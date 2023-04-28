# Mathematical Formulation

This package's mathematical formulation conventions were inspired by _BQPJSON_'s.

```math
\min \vert \max f(\mathbf{x}) = \alpha \left[{ \sum_{i < j} Q_{i, j} x_{i} x_{j} + \sum_{i} \ell_{i} x_{i} + \beta }\right]
```

where ``\alpha, \beta \in \mathbb{R}`` are the _scale_ and _offset_ parameters.
The vector ``\mathbf{\ell} \in \mathbb{R}^{n}`` stores the linear terms and ``Q \in \mathbb{R}^{n \times n}``, the quadratic interaction matrix, is assumed to be in the strictly upper triangular form.

!!! info
    Internally, any problem loaded with this package will be converted to the normal form presented above.

!!! info
    The scaling factor ``\alpha`` must be positive.

## Variable Domains

Available domains are represented by the `BoolDomain` and `SpinDomain` types, respectively, ``x \in \mathbb{B} = \lbrace 0, 1 \rbrace`` and ``s \in \mathbb{S} = \lbrace -1, 1 \rbrace``.
Conversion between domains follows the identity

```math
s = 2x - 1
```