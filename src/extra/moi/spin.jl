raw"""
    __moi_spin_set

This function has no methods, allowing the MOI extension to implement

```julia
__moi_spin_set() = Spin
```

The other packages will implement

```julia
const Spin = __moi_spin_set()
```

In this way, it's possible to circumvent the limitation that package extensions
can only provide additional methods, and not export new constants and types.
"""
function __moi_spin_set end
