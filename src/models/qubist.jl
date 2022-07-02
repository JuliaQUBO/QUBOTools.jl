@doc raw"""
""" mutable struct Qubist{D <: SpinDomain} <: Model{D}
    data::Dict{String, Any}

    function Qubist{D}(data::Dict{String, Any}) where D <: SpinDomain
        new{D}(data)
    end

    function Qubist(data::Dict{String, Any})
        Qubist{SpinDomain{Int}}(data)
    end
end