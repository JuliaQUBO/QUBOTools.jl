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

function swap_domain(
    source::Domain,
    target::Domain,
    L̄::Dict{Int,T},
    Q̄::Dict{Tuple{Int,Int},T},
    ᾱ::Union{T,Nothing} = nothing,
    β̄::Union{T,Nothing} = nothing,
) where {T}
    α = something(ᾱ, one(T))
    β = something(β̄, zero(T))
    L = sizehint!(Dict{Int,T}(), length(L̄))
    Q = sizehint!(Dict{Tuple{Int,Int},T}(), length(Q̄))

    if source === target
        copy!(L, L̄)
        copy!(Q, Q̄)
    elseif source === SpinDomain && target === BoolDomain
        for (i, c) in L̄
            β -= c
            L[i] = get(L, i, zero(T)) + 2c
        end

        for ((i, j), c) in Q̄
            β         += c
            L[i]      = get(L, i, zero(T)) - 2c
            L[j]      = get(L, j, zero(T)) - 2c
            Q[(i, j)] = get(Q, (i, j), zero(T)) + 4c
        end
    elseif source === BoolDomain && target === SpinDomain
        for (i, c) in L̄
            β += c / 2
            L[i] = get(L, i, zero(T)) + c / 2
        end
    
        for ((i, j), c) in Q̄
            β         += c / 4
            L[i]      = get(L, i, zero(T)) + c / 4
            L[j]      = get(L, j, zero(T)) + c / 4
            Q[(i, j)] = get(Q, (i, j), zero(T)) + c / 4
        end
    else
        error("There's no valid conversion between '$source' and '$target'")
    end

    return (L, Q, α, β)
end

function _map_terms(
    _linear_terms::Dict{S,T},
    _quadratic_terms::Dict{Tuple{S,S},T},
    variable_map::Dict{S,Int},
) where {S,T}
    linear_terms = Dict{Int,T}(variable_map[i] => l for (i, l) in _linear_terms)
    quadratic_terms = Dict{Tuple{Int,Int},T}(
        (variable_map[i], variable_map[j]) => q for ((i, j), q) in _quadratic_terms
    )

    return (linear_terms, quadratic_terms)
end

function _inv_terms(
    _linear_terms::Dict{Int,T},
    _quadratic_terms::Dict{Tuple{Int,Int},T},
    variable_inv::Dict{Int,S},
) where {S,T}
    linear_terms = Dict{S,T}(variable_inv[i] => l for (i, l) in _linear_terms)
    quadratic_terms = Dict{Tuple{S,S},T}(
        (variable_inv[i], variable_inv[j]) => q for ((i, j), q) in _quadratic_terms
    )

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
    variable_map = Dict{V,Int}(
        v => k for (k, v) in enumerate(sort(collect(variable_set); lt = varcmp))
    )
    variable_inv = Dict{Int,V}(v => k for (k, v) in variable_map)

    return (variable_map, variable_inv)
end

function domains()
    return Type[dom for dom in subtypes(Domain) if dom !== UnknownDomain]
end

function formats()
    domain_list = domains()
    format_list = subtypes(AbstractFormat)

    return Type[fmt{dom} for dom in domain_list, fmt in format_list if (fmt{<:dom} <: fmt)]
end

function infer_format(path::AbstractString)
    pieces = reverse(split(basename(path), "."))

    if length(pieces) == 1
        format_error("Unable to infer QUBO format from file without an extension")
    else
        format_hint, domain_hint, _... = pieces
    end

    return infer_format(Symbol(domain_hint), Symbol(format_hint))
end

function infer_format(domain_hint::Symbol, format_hint::Symbol)
    return infer_format(Val(domain_hint), Val(format_hint))
end

function infer_format(::Val, format_hint::Val)
    return infer_format(format_hint)
end

function infer_format(format_hint::Symbol)
    return infer_format(Val(format_hint))
end