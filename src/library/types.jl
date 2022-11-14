@doc raw"""
    VariableDomain

""" abstract type VariableDomain end

const 𝔻 = VariableDomain

Base.Broadcast.broadcastable(D::VariableDomain) = Ref(D)

@doc raw"""
    SpinDomain <: VariableDomain

```math
s \in \lbrace{-1, 1}\rbrace
```
""" struct SpinDomain <: VariableDomain end

const 𝕊 = SpinDomain

@doc raw"""
    BoolDomain <: VariableDomain

```math
x \in \lbrace{0, 1}\rbrace
```
""" struct BoolDomain <: VariableDomain end

const 𝔹 = BoolDomain
