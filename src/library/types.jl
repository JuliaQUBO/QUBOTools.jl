# -*- :: Domains :: -*- #
abstract type VariableDomain end

@doc raw"""
    SpinDomain <: VariableDomain

```math
s \in \lbrace{-1, 1}\rbrace
```
""" struct SpinDomain <: VariableDomain end

@doc raw"""
    BoolDomain <: VariableDomain

```math
x \in \lbrace{0, 1}\rbrace
```
""" struct BoolDomain <: VariableDomain end