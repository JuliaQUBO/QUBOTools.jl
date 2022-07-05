@doc raw"""
""" struct MiniZinc{D <: VariableDomain} <: AbstractBQPModel{D}
    data::Dict{String, Any}

    function MiniZinc{D}(data::Dict{String, Any}) where D <: VariableDomain
        new{D}(data)
    end
end

