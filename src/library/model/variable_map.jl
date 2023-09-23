@doc raw"""
    VariableMap{V}

Establishes a bijection between variables and their indices.
The interface for accessing this mapping relies on [`QUBOTools.index`](@ref) and [`QUBOTools.variable`](@ref).
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

function Base.length(vm::VariableMap)
    return length(vm.inv)
end

function Base.iterate(vm::VariableMap, i::Integer = 1)
    if 1 <= i <= length(vm)
        return ((i, vm.inv[i]), i + 1)
    else
        return nothing
    end
end

function index(vm::VariableMap{V}, v::V) where {V}
    if haskey(vm.map, v)
        return vm.map[v]
    else
        error("Variable '$v' does not belong to the mapping")
    end
end

function variable(vm::VariableMap, i::Integer)
    n = length(vm)

    if 1 <= i <= n
        return vm.inv[i]
    else
        error("Variable index '$i' is out of range '[1, $n]'")
    end
end
