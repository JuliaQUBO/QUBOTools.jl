# File Formats

|              Format              | Read  | Write | Model | Solutions | Start | Metadata |
| :------------------------------: | :---: | :---: | :---: | :-------: | :---: | :------: |
| [BQPJSON](../formats/BQPJSON.md) |   ✅   |   ✅   |   ✅   |     ✅     |   ❌   |    ✅     |
|   [QUBin](../formats/QUBin.md)   |   ✅   |   ✅   |   ✅   |     ✅     |   ✅   |    ✅     |
|  [Qubist](../formats/Qubist.md)  |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ❌     |
|    [QUBO](../formats/QUBO.md)    |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |

## Defining a Custom File Format

```@example custom-file-format
using QUBOTools

struct SuperFormat <: QUBOTools.AbstractFormat
    super::Bool

    SuperFormat(super::Bool = true) = new(super)
end
```

### Writing Models

To write a model using `SuperFormat`, one must implement the

```julia
QUBOTools.write_model(io::IO, ::QUBOTools.AbstractModel{V,T,U}, ::SuperFormat) where {V,T,U}
```

method for the custom format.

!!! info
    This assumption is valid for text-based and binary formats.
    If you pretend to write in a format that does not rely on `io::IO` (such as [`QUBOTools.QUBin`](@ref)),
    you should also implement

    ```julia
    QUBOTools.write_model(filepath::AbstractString, ::QUBOTools.AbstractModel{V,T,U}, ::SuperFormat) where {V,T,U}
    ```

```@example custom-file-format
function QUBOTools.write_model(io::IO, model::QUBOTools.AbstractModel, fmt::SuperFormat)
    if fmt.super
        println(io, "Format Type: SUPER")

        _write_super_model(io, model)
    else
        println(io, "Format Type: Regular")

        _write_regular_model(io, model)
    end
    
    return nothing
end
```

### Reading Models

```@example custom-file-format
function QUBOTools.read_model(io::IO, fmt::SuperFormat)
    header = readline(io)

    if fmt.super
        @assert("SUPER" in header, "Invalid header: '$header' is not SUPER!")

        return _read_super_model(io)
    else
        return _read_regular_model(io)
    end
end
```

!!! info
    [`QUBOTools.read_model`](@ref) should return a [`QUBOTools.Model`](@ref) instance.
