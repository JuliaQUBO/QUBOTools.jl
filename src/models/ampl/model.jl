const AMPL_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

@doc raw"""
""" mutable struct AMPL{D<:VariableDomain} <: AbstractBQPModel{D}
    backend::AMPL_BACKEND_TYPE{D}

    function AMPL{D}(args...; kws...)
        backend = AMPL_BACKEND_TYPE{D}(args...; kws...)
        
        new{D}(backend)
    end
end