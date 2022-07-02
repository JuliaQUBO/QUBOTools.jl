@doc raw"""
""" mutable struct HFS{D <: BoolDomain} <: Model{D}
    data::Dict{String, Any}

    function HFS{D}(data::Dict{String, Any}) where D <: BoolDomain
        new{D}(data)
    end

    function HFS(data::Dict{String, Any})
        HFS{BoolDomain{Int}}(data)
    end
end