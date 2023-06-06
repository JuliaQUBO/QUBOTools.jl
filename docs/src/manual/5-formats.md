# Formats

## Styles

## Custom File Format

```@example file-format
using QUBOTools

struct SuperFormat <: QUBOTools.AbstractFormat
    domain::Union{QUBOTools.BoolDomain,QUBOTools.SpinDomain,Nothing}
    super::Bool

    function SuperFormat(
        dom::Union{QUBOTools.BoolDomain,QUBOTools.SpinDomain,Nothing} = nothing,
        sty::Nothing                                                  = nothing;
        super::Bool                                                   = true
    )
        return new(dom, super)
    end
end

QUBOTools.domain(fmt::SuperFormat) = fmt.domain

QUBOTools.supports_domain(::SuperFormat, ::Nothing) = true
QUBOTools.supports_domain(::SuperFormat, ::QUBOTools.BoolDomain) = true
QUBOTools.supports_domain(::SuperFormat, ::QUBOTools.SpinDomain) = true

QUBOTools.infer_format(::Val{:super}) = SuperFormat(nothing)
```