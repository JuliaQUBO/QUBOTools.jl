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

    (bool_offset, bool_linear_terms, bool_quadratic_terms)
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

    (spin_offset, spin_linear_terms, spin_quadratic_terms)
end