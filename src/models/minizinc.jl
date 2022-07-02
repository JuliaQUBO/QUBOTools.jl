@doc raw"""
""" struct MiniZinc{D <: Domain} <: Model{D}
    data::Dict{String, Any}

    function MiniZinc{D}(data::Dict{String, Any}) where D <: Domain
        new{D}(data)
    end
end

