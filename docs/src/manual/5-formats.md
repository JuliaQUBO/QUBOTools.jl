# Formats

|              Format              | Read  | Write | Model | Solutions | Start | Metadata |
| :------------------------------: | :---: | :---: | :---: | :-------: | :---: | :------: |
| [BQPJSON](../formats/BQPJSON.md) |   ✅   |   ✅   |   ✅   |     ✅     |   ❌   |    ✅     |
|   [QUBin](../formats/QUBin.md)   |   ✅   |   ✅   |   ✅   |     ✅     |   ✅   |    ✅     |
|  [Qubist](../formats/Qubist.md)  |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ❌     |
|    [QUBO](../formats/QUBO.md)    |   ✅   |   ✅   |   ✅   |     ❌     |   ❌   |    ✅     |

## Custom File Format

```@example file-format
using QUBOTools

struct SuperFormat <: QUBOTools.AbstractFormat
    super::Bool

    SuperFormat(super::Bool = true) = new(super)
end
```