# -*- :: Domains :: -*- #
abstract type VariableDomain end

@doc raw"""
    SpinDomain()

```math
s \in \{-1, 1\}
```
""" struct SpinDomain <: VariableDomain end
@doc raw"""
    BoolDomain()

```math
x \in \{0, 1\}
```
""" struct BoolDomain <: VariableDomain end

# -*- :: Models :: -*- #
abstract type AbstractBQPModel{D <: VariableDomain} end

# -*- :: Interface :: -*- #

# ~*~ Validation ~*~ #
function Base.isvalid(::AbstractBQPModel)
    false
end

# ~*~ I/O ~*~ #
function Base.read(::IO, M::Type{<:AbstractBQPModel})
    error("'Base.read' not implemented for model of type '$(M)'")
end

function Base.write(::IO, m::AbstractBQPModel)
    error("'Base.write' not implemented for model of type '$(typeof(m))'")
end

function Base.convert(M::Type{<:AbstractBQPModel}, m::AbstractBQPModel)
    error("'Base.convert' not implemented for turning model of type '$(typeof(m))' into $(M)")
end

function Base.convert(::Type{M}, model::M) where {M <: AbstractBQPModel}
    model # Short-circuit! Yeah!
end

function Base.read(path::AbstractString, M::Type{<:AbstractBQPModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(path::AbstractString, M::Type{<:AbstractBQPModel})
    open(path, "w") do io
        return write(io, M)
    end
end