raw"""
    __moi_num_reads

This function has no methods, allowing the MOI extension to provide an attribute.

```julia
__moi_num_reads() = NumberOfReads
```

The other packages will implement

```julia
const NumberOfReads = __moi_num_reads()
```

"""
function __moi_num_reads end
