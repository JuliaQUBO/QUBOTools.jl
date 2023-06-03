@doc raw"""
    AbstractDevice{A<:AbstractArchitecture,V,T,U} <: AbstractModel{V,T,U}

A device instance is meant to represent an specific hardware or software device.
It is the concrete implementation of an architecture.
For example, the topology of a device must be contained within the ideal topology of its architecture.
"""
abstract type AbstractDevice{A<:AbstractArchitecture,V,T,U} <: AbstractModel{V,T,U} end
