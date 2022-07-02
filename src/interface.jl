# -*- :: Domains :: -*- #
abstract type Domain end

@doc raw"""
""" struct SpinDomain <: Domain end
@doc raw"""
""" struct BoolDomain <: Domain end

# -*- :: Models :: -*- #
abstract type Model{D} end

# -*- :: Functions :: -*- #
@doc raw"""
""" function domain end

domain(::Model{D}) where D <: Domain = D
domain(::Type{<:Model{D}}) where D <: Domain = D

@doc raw"""
""" function validate end

function validate(::Model)
    nothing
end

# -*- :: Interface :: -*- #
function Base.read(::IO, M::Type{<:Model})
    @error "Base.read not implemented for model of type '$(M)'"
end

function Base.write(::IO, m::Model)
    @error "Base.write not implemented for model of type '$(typeof(m))'"
end

function Base.convert(M::Type{<:Model}, m::Model)
    @error "Base.convert not implemented for turning model of type '$(typeof(m))' into $(M)"
end

function Base.read(path::AbstractString, M::Type{<:Model})
    open(path, "r") do io
        return read(io, M)
    end
end

function Base.write(path::AbstractString, M::Type{<:Model})
    open(path, "w") do io
        return write(io, M)
    end
end