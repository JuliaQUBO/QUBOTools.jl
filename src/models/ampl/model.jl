const AMPL_BACKEND_TYPE{D} = StandardBQPModel{Int,Int,Float64,D}

@doc raw"""
""" mutable struct AMPL{D<:BoolDomain} <: AbstractBQPModel{D}
    backend::AMPL_BACKEND_TYPE{D}

    function AMPL{D}(args...; kws...) where {D <: BoolDomain}
        backend = AMPL_BACKEND_TYPE{D}(args...; kws...)
        
        new{D}(backend)
    end
end

BQPIO.backend(model::AMPL) = model.backend