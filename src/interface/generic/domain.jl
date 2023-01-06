QUBOTools.Domain(dom::Domain)  = dom
QUBOTools.Domain(dom::Symbol)  = Domain(Val(dom))

Base.Broadcast.broadcastable(dom::Domain) = Ref(dom)

@doc raw"""
    BoolDomain <: Domain

```math
x \in \mathbb{B} = \lbrace{0, 1}\rbrace
```
""" struct BoolDomain <: Domain end

const 𝔹 = BoolDomain()

QUBOTools.Domain(::Val{:bool}) = 𝔹

Base.show(io::IO, ::BoolDomain) = print(io, "𝔹")

@doc raw"""
    SpinDomain <: Domain

```math
s \in \mathbb{S} = \lbrace{-1, 1}\rbrace
```
""" struct SpinDomain <: Domain end

const 𝕊 = SpinDomain()

QUBOTools.Domain(::Val{:spin}) = 𝕊

Base.show(io::IO, ::SpinDomain) = print(io, "𝕊")

function domain_types()
    return Type[Nothing; subtypes(Domain)]
end

function domains()
    return Union{Domain,Nothing}[dom() for dom in domain_types()]
end

function supports_domain(::Type{F}, ::Nothing) where {F<:AbstractFormat}
    return false
end

function supports_domain(::Type{F}, ::Domain) where {F<:AbstractFormat}
    return false
end
