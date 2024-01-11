raw"""
    __moi_qubo_model

This function has no methods, allowing the MOI extension to provide a QUBO
model type.

```julia
__moi_qubo_model() = QUBOModel
```

The other packages will implement

```julia
const QUBOModel = __moi_qubo_model()
```

"""
function __moi_qubo_model end
