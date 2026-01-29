# File Formats

|              Format                | Read  | Write | Model | Solutions | Start | Metadata |
| :--------------------------------: | :---: | :---: | :---: | :-------: | :---: | :------: |
| [BQPJSON](../formats/bqpjson.md)   |   ✅   |   ✅   |   ✅   |     ✅     |   ❌   |    ✅     |
| [MiniZinc](../formats/minizinc.md) |   ❌   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |
|   [QUBin](../formats/qubin.md)     |   ✅   |   ✅   |   ✅   |     ✅     |   ✅   |    ✅     |
|  [Qubist](../formats/qubist.md)    |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ❌     |
|    [QUBO](../formats/qubo.md)      |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |
|    [Rudy](../formats/rudy.md)      |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |

## Defining a Custom File Format

```@example custom-file-format
import QUBOTools

function QUBOTools.Format{:super}(; super::Bool = true, kws...)
    settings = Dict{Symbol,Any}()

    settings[:super] = super

    return QUBOTools.Format{:super}(settings)
end
```

### Writing Models

To write a model using `SuperFormat`, one must implement the

```julia
QUBOTools.write_model(io::IO, ::QUBOTools.AbstractModel{V,T,U}, ::QUBOTools.Format{:super}) where {V,T,U}
```

method for the custom format.

!!! info
    This assumption is valid for text-based and binary formats.
    If you pretend to write in a format that does not rely on `io::IO` (such as [`QUBOTools.qubin_fmt`](@ref)),
    you should also implement

    ```julia
    QUBOTools.write_model(filepath::AbstractString, ::QUBOTools.AbstractModel{V,T,U}, ::QUBOTools.Format{:super}) where {V,T,U}
    ```

```@example custom-file-format
function QUBOTools.write_model(io::IO, model::QUBOTools.AbstractModel, fmt::QUBOTools.Format{:super})
    if fmt[:super]
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
function QUBOTools.read_model(io::IO, fmt::QUBOTools.Format{:super})
    header = readline(io)

    if fmt[:super]
        @assert("SUPER" in header, "Invalid header: '$header' is not SUPER!")

        return _read_super_model(io)
    else
        return _read_regular_model(io)
    end
end
```

!!! info
    [`QUBOTools.read_model`](@ref) must return a [`QUBOTools.Model`](@ref) instance.
