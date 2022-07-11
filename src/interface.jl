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

@doc raw"""
    backend(::Any)

""" function backend end

backend(::Any) = nothing

@doc raw"""
    isvalidbridge(source::M, target::M, ::Type{<:AbstractBQPModel}; kws...) where M <: AbstractBQPModel

Checks if the `source` model is equivalent to the `target` reference modulo the given origin type.
Key-word arguments `kws...` are passed to interal `isapprox(::T, ::T; kws...)` calls.

""" function isvalidbridge end

function isvalidbridge(source::M, target::M, ::Type{<:AbstractBQPModel}; kws...) where M <: AbstractBQPModel
    false
end

@doc raw"""
    energy(state::Any, model::AbstractBQPModel)

This function aims to evaluate the energy of a given state under some BQP Model.
Scale and offset factors are assumed to be taken into account.
""" function energy end

function energy(state, model::AbstractBQPModel)
    backend = BQPIO.backend(model)

    @assert !isnothing(backend)
    
    energy(state, backend)
end

# ~*~ I/O ~*~ #
function Base.read(::IO, M::Type{<:AbstractBQPModel})
    error("'Base.read' not implemented for model of type '$(M)'")
end

function Base.read(path::AbstractString, M::Type{<:AbstractBQPModel})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(::IO, model::AbstractBQPModel)
    error("'Base.write' not implemented for model of type '$(typeof(model))'")
end

function Base.write(path::AbstractString, model::AbstractBQPModel)
    open(path, "w") do io
        return write(io, model)
    end
end

function Base.convert(M::Type{<:AbstractBQPModel}, model::AbstractBQPModel)
    error("'Base.convert' not implemented for turning model of type '$(typeof(model))' into $(M)")
end

function Base.convert(::Type{M}, model::M) where {M <: AbstractBQPModel}
    model # Short-circuit! Yeah!
end