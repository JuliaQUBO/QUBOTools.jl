"""
    _isapproxdict(::Dict{K,T}, ::Dict{K,T}; kw...) where {K, T}

Tells if two dictionaries have the same keys and approximate values for those keys.
The keyword arguments are passed to `isapprox` calls.
"""
function _isapproxdict end

function _isapproxdict(x::Dict{K,T}, y::Dict{K,T}; kw...) where {K,T<:Real}
    if length(x) == length(y)
        return all(haskey(y, k) && isapprox(x[k], y[k]; kw...) for k in keys(x))
    else
        return false
    end
end

function _map_terms(
    _linear_terms::Dict{S,T},
    _quadratic_terms::Dict{Tuple{S,S},T},
    variable_map::Dict{S,Int},
) where {S,T}
    linear_terms    = sizehint!(Dict{Int,T}(), length(_linear_terms))
    quadratic_terms = sizehint!(Dict{Tuple{Int,Int},T}(), length(_quadratic_terms))

    for (i, l) in _linear_terms
        linear_terms[variable_map[i]] = l
    end

    for ((i, j), c) in _quadratic_terms
        quadratic_terms[(variable_map[i], variable_map[j])] = c
    end

    return (linear_terms, quadratic_terms)
end

function _inv_terms(
    _linear_terms::Dict{Int,T},
    _quadratic_terms::Dict{Tuple{Int,Int},T},
    variable_inv::Dict{Int,S},
) where {S,T}
    linear_terms    = sizehint!(Dict{S,T}(), length(_linear_terms))
    quadratic_terms = sizehint!(Dict{Tuple{S,S},T}(), length(_quadratic_terms))

    for (i, c) in _linear_terms
        linear_terms[variable_inv[i]] = c
    end

    for ((i, j), c) in _quadratic_terms
        quadratic_terms[(variable_inv[i], variable_inv[j])] = c
    end

    return (linear_terms, quadratic_terms)
end

function _normal_form(
    _linear_terms::Dict{V,T},
    _quadratic_terms::Dict{Tuple{V,V},T},
) where {V,T}
    linear_terms    = Dict{V,T}()
    quadratic_terms = Dict{Tuple{V,V},T}()
    variable_set    = Set{V}()

    sizehint!(linear_terms, length(_linear_terms))
    sizehint!(quadratic_terms, length(_quadratic_terms))

    for (i, l) in _linear_terms
        push!(variable_set, i)

        l += get(linear_terms, i, zero(T))

        if iszero(l)
            delete!(linear_terms, i)
        else
            linear_terms[i] = l
        end
    end

    for ((i, j), q) in _quadratic_terms

        push!(variable_set, i, j)

        if i == j
            q += get(linear_terms, i, zero(T))
            if iszero(q)
                delete!(linear_terms, i)
            else
                linear_terms[i] = q
            end
        elseif i ≺ j
            q += get(quadratic_terms, (i, j), zero(T))
            if iszero(q)
                delete!(quadratic_terms, (i, j))
            else
                quadratic_terms[(i, j)] = q
            end
        else # i > j
            q += get(quadratic_terms, (j, i), zero(T))
            if iszero(q)
                delete!(quadratic_terms, (j, i))
            else
                quadratic_terms[(j, i)] = q
            end
        end
    end

    return (linear_terms, quadratic_terms, variable_set)
end

function _build_mapping(variable_set::Set{V}) where {V}
    variable_map = sizehint!(Dict{V,Int}(), length(variable_set))
    variable_inv = sizehint!(Dict{Int,V}(), length(variable_map))

    for (k, v) in enumerate(sort!(collect(variable_set); lt = varlt))
        variable_map[v] = k
        variable_inv[k] = v
    end

    return (variable_map, variable_inv)
end
