@doc raw"""
    VariableMap{V}
"""
struct VariableMap{V}
    map::Dict{V,Int}
    inv::Vector{V}

    function VariableMap{V}(
        variables::X,
    ) where {V,X<:Union{AbstractVector{V},AbstractSet{V}}}
        inv = sort!(collect(variables); lt = varlt)
        map = Dict{V,Int}(v => i for (i, v) in enumerate(inv))

        return new(map, inv)
    end
end
