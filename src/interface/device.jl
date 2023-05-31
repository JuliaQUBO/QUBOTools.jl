@doc raw"""
    AbstractDevice{A<:AbstractArchitecture,V,T,U} <: AbstractModel{V,T,U}
"""
abstract type AbstractDevice{A<:AbstractArchitecture,V,T,U} <: AbstractModel{V,T,U} end
