function _parse_line!(fmt::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    _parse_comment!(fmt, data, line)   && return nothing
    _parse_domain!(fmt, data, line)    && return nothing
    _parse_factor!(fmt, data, line)    && return nothing
    _parse_variable!(fmt, data, line)  && return nothing
    _parse_objective!(fmt, data, line) && return nothing
    _parse_sense!(fmt, data, line)     && return nothing

    syntax_warning("'$line'")
end

function _parse_comment!(fmt::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(_MINIZINC_RE_COMMENT, line)

    if isnothing(m)
        return false
    end

    if isnothing(m[1])
        return true
    end

    content = strip(m[1])

    return _parse_metadata!(fmt, data, content)
end

function _parse_metadata!(::MiniZinc, data::Dict{Symbol,Any}, content::AbstractString)
    m = match(_MINIZINC_RE_METADATA, content)

    if isnothing(m)
        return true
    end

    key = string(m[1])
    val = string(m[2])

    if key == "id"
        data[:id] = tryparse(Int, val)
    elseif key == "description"
        data[:description] = val
    else
        data[:metadata][key] = JSON.parse(val)
    end

    return true
end

function _parse_domain!(::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(_MINIZINC_RE_DOMAIN, line)

    if isnothing(m)
        return false
    end

    a = tryparse(Int, m[1])
    b = tryparse(Int, m[2])

    if isnothing(a) || isnothing(b)
        syntax_error("Failed to parse variable domain '$(line)'")
    end

    Ω = Set{Int}([a, b])

    if Ω == Set{Int}([-1, 1])
        data[:domain] = SpinDomain()
    elseif Ω == Set{Int}([0, 1])
        data[:domain] = BoolDomain()
    else
        syntax_error("Invalid variable set '$(Ω)'")
    end

    return true
end

function _parse_factor!(::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(_MINIZINC_RE_FACTOR, line)

    if isnothing(m)
        return false
    end

    var = string(m[1])
    val = string(m[2])

    if var == "scale"
        data[:scale] = tryparse(Float64, val)
    elseif var == "offset"
        data[:offset] = tryparse(Float64, val)
    end # ignore other constant definitions

    return true
end

function _parse_variable!(::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(_MINIZINC_RE_VAR_DEF, line)

    if isnothing(m)
        return false
    end

    var_id = tryparse(Int, m[1])

    if isnothing(var_id)
        syntax_error("Error while parsing variable id '$var_id'")
    end

    push!(data[:variable_set], var_id)

    return true
end

function _parse_objective!(::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(_MINIZINC_RE_OBJECTIVE, line)

    if isnothing(m)
        return false    
    end

    objective_expr = strip(m[1])

    if objective_expr == "0"
        return true
    end

    for term in strip.(split(objective_expr, '+'))
        term_atoms = strip.(split(term, "*"))

        coef = 1.0
        var1 = nothing
        var2 = nothing

        for atom in term_atoms
            m = match(_MINIZINC_RE_VAR, atom)

            if !isnothing(m) # variable
                var_id = tryparse(Int, m[1])

                if isnothing(var_id)
                    error("Error while parsing variable id")
                elseif var_id ∉ data[:variable_set]
                    error("Unknown variable '$var_id'")
                end

                if isnothing(var1)
                    var1 = var_id
                elseif isnothing(var2)
                    var2 = var_id
                else
                    error("Terms should be at most quadratic")
                end
            else
                coef *= parse(Float64, atom)
            end
        end

        if isnothing(var1)
            error("Constant terms are not allowed in objective function")
        elseif isnothing(var2)
            L = data[:linear_terms]
            L[var1] = get(L, var1, 0.0) + coef
        else
            Q = data[:quadratic_terms]
            Q[(var1, var2)] = get(Q, (var1, var2), 0.0) + coef
        end
    end

    return true
end

function _parse_sense!(::MiniZinc, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(_MINIZINC_RE_SENSE, line)

    if isnothing(m)
        return false    
    end

    data[:mzn_sense] = string(m[1])

    if data[:mzn_sense] == "minimize"
        data[:sense] = :min
    elseif data[:mzn_sense] == "maximize"
        data[:sense] = :max
    else
        format_error("Invalid optimization sense '$(data[:mzn_sense])")
    end

    return true
end

function read_model(io::IO, fmt::MiniZinc)
    data = Dict{Symbol,Any}(
        :domain          => nothing,
        :id              => nothing,
        :scale           => nothing,
        :offset          => nothing,
        :variable_set    => Set{Int}(),
        :linear_terms    => Dict{Int,Float64}(),
        :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
        :metadata        => nothing,
        :description     => nothing,
        :sense           => nothing,
    )

    for line in strip.(readlines(io))
        if isempty(line)
            continue # ~ skip
        end

        _parse_line!(fmt, data, line)
    end

    target_domain = something(domain(fmt), data[:domain])

    L, Q, α, β = swap_domain(
        data[:domain],
        target_domain,
        data[:linear_terms],
        data[:quadratic_terms],
        data[:scale],
        data[:offset],
    )

    return StandardModel(
        L,
        Q,
        data[:variable_set];
        scale       = α,
        offset      = β,
        id          = data[:id],
        description = data[:description],
        metadata    = data[:metadata],
    )
end
