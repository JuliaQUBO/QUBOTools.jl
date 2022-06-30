# -*- :: Domains :: -*- #
abstract type Domain{T <: Integer} end

@doc raw"""
""" struct SpinDomain{T <: Signed} <: Domain{T}

    function SpinDomain{T}() where T <: Integer
        new{T}()
    end

    function SpinDomain()
        SpinDomain{Int}()
    end
end

@doc raw"""
""" struct BoolDomain{T <: Integer} <: Domain{T}

    function BoolDomain{T}() where T <: Integer
        new{T}()
    end

    function BoolDomain()
        BoolDomain{Int}()
    end
end

# -*- :: Models :: -*- #
abstract type Model{D <: Domain} end

@doc raw"""
""" struct BQPJSON{D <: Domain} <: Model{D} end

@doc raw"""
""" struct Qubist{D <: SpinDomain} <: Model{D} end

@doc raw"""
""" struct QUBO{D <: BoolDomain} <: Model{D} end

@doc raw"""
""" struct MiniZinc{D <: Domain} <: Model{D} end

@doc raw"""
""" struct HFS{D <: BoolDomain} <: Model{D} end

# -*- :: Functions :: -*- #
@doc raw"""
""" function domain end

domain(::Model{D}) where D <: Domain = D
domain(::Type{<:Model{D}}) where D <: Domain = D

@doc raw"""
""" function validate end

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