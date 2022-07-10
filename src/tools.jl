@doc raw"""
""" function isapproxdict end

function isapproxdict(x::Dict{K, T}, y::Dict{K, T}; kw...) where {K, T <: Number}
    (length(x) == length(y)) && all(haskey(y, k) && isapprox(x[k], y[k]; kw...) for k in keys(x))
end

@doc raw"""
""" function swapdomain end

function swapdomain(
        ::Type{<:SpinDomain},
        ::Type{<:BoolDomain},
        offset::T,
        linear_terms::Dict{Int, T},
        quadratic_terms::Dict{Tuple{Int, Int}, T}
    ) where T

    bool_offset          = offset
    bool_linear_terms    = Dict{Int, T}()
    bool_quadratic_terms = Dict{Tuple{Int, Int}, T}()

    for (i, h) in linear_terms
        bool_linear_terms[i] = get(bool_linear_terms, i, zero(T)) + 2h
        bool_offset -= h
    end

    for ((i, j), Q) in quadratic_terms
        bool_quadratic_terms[(i, j)] = get(bool_quadratic_terms, (i, j), zero(T)) + 4Q
        bool_quadratic_terms[(i, i)] = get(bool_quadratic_terms, (i, i), zero(T)) - 2Q
        bool_quadratic_terms[(j, j)] = get(bool_quadratic_terms, (j, j), zero(T)) - 2Q
        bool_offset += Q
    end

    return (bool_offset, bool_linear_terms, bool_quadratic_terms)
end

function swapdomain(
        ::Type{<:BoolDomain},
        ::Type{<:SpinDomain},
        offset::T,
        linear_terms::Dict{Int, T},
        quadratic_terms::Dict{Tuple{Int, Int}, T}
    ) where T

    spin_offset          = offset
    spin_linear_terms    = Dict{Int, T}()
    spin_quadratic_terms = Dict{Tuple{Int, Int}, T}()

    for (i, q) in linear_terms
        spin_linear_terms[i] = get(spin_linear_terms, i, zero(T)) + q / 2
        spin_offset += q / 2
    end

    for ((i, j), Q) in quadratic_terms
        spin_quadratic_terms[(i, j)] = get(spin_quadratic_terms, (i, j), zero(T)) + Q / 4
        spin_quadratic_terms[(i, i)] = get(spin_quadratic_terms, (i, i), zero(T)) + Q / 4
        spin_quadratic_terms[(j, j)] = get(spin_quadratic_terms, (j, j), zero(T)) + Q / 4
        spin_offset += Q / 4
    end

    return (spin_offset, spin_linear_terms, spin_quadratic_terms)
end

@doc raw"""
""" function build_varmap end

function build_varmap(linear_terms::Dict{Int, T}, quadratic_terms::Dict{Tuple{Int, Int}, T}) where T
    variables = Set{Int}()

    for i in keys(linear_terms)
        push!(variables, i)
    end

    for (i, j) in keys(quadratic_terms)
        push!(variables, i, j)
    end

    Dict{Int, Int}(
        i => k for (k, i) in enumerate(sort(collect(variables)))
    )
end

@doc raw"""
""" function build_varinv end

function build_varinv(variable_map::Dict{Int, Int})
    Dict{Int, Int}(i => k for (k, i) in variable_map)
end

@doc raw"""
""" function build_varbij end

function build_varbij(linear_terms::Dict{Int, T}, quadratic_terms::Dict{Tuple{Int, Int}, T}) where T
    variable_map = build_varmap(linear_terms, quadratic_terms)
    variable_inv = build_varinv(variable_map)

    return (variable_map, variable_inv)
end

@doc raw"""
""" function map_terms end

function map_terms(linear_terms::Dict{Int, T}, quadratic_terms::Dict{Tuple{Int, Int}, T}) where T
    map_linear_terms    = Dict{Int, T}()
    map_quadratic_terms = Dict{Tuple{Int, Int}, T}()

    sizehint!(map_linear_terms, length(linear_terms))
    sizehint!(map_quadratic_terms, length(quadratic_terms))

    for (i, l) in linear_terms
        l += get(map_linear_terms, i, zero(T))
        if iszero(l)
            delete!(map_linear_terms, i)
        else
            map_linear_terms[i] = l
        end
    end

    for ((i, j), q) in quadratic_terms
        if i == j
            q += get(map_linear_terms, i, zero(T))
            if iszero(q)
                delete!(map_linear_terms, i)
            else
                map_linear_terms[i] = q
            end
        elseif i < j
            q += get(map_quadratic_terms, (i, j), zero(T))
            if iszero(q)
                delete!(map_quadratic_terms, (i, j))
            else
                map_quadratic_terms[(i, j)] = q
            end
        else # i > j
            q += get(map_quadratic_terms, (j, i), zero(T))
            if iszero(q)
                delete!(map_quadratic_terms, (j, i))
            else
                map_quadratic_terms[(j, i)] = q
            end
        end
    end
        
    return (map_linear_terms, map_quadratic_terms)
end

@doc raw"""
""" function map_state end

function map_state(state::Vector{U}, ::Dict{Int, S}) where {S <: Any, U <: Integer}
    state
end

function map_state(state::Dict{S, U}, variable_inv::Dict{Int, S}) where {S <: Any, U <: Integer}
    U[state[variable_inv[i]] for i = 1:length(variable_inv)]
end