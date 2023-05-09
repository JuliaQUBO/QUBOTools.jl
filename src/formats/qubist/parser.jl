function _parse_entry!(::Qubist, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(r"^([0-9]+) ([0-9]+) ([+-]?([0-9]*[.])?[0-9]+)$", line)

    if isnothing(m)
        return false
    end

    i = tryparse(Int, m[1])
    j = tryparse(Int, m[2])
    c = tryparse(Float64, m[3])

    if isnothing(i) || isnothing(j) || isnothing(c)
        syntax_error("Invalid entry: '$line'")
    elseif i == j
        L    = data[:linear_terms]
        L[i] = get(L, i, 0.0) + c
    else
        Q         = data[:quadratic_terms]
        Q[(i, j)] = get(Q, (i, j), 0.0) + c
    end

    return true
end

function _parse_header!(::Qubist, data::Dict{Symbol,Any}, line::AbstractString)
    m = match(r"^([0-9]+) ([0-9]+)$", line)

    if isnothing(m)
        return false
    end

    domain_size = tryparse(Int, m[1])
    total_size  = tryparse(Int, m[2])

    if isnothing(domain_size) || isnothing(total_size)
        syntax_error("Invalid header: '$line'")
    end

    # TODO: `sizehint!` linear and quadratic collections
    # IDEA: 
    #   1. linear_size + quadratic_size = total_size
    #   2. domain_size * linear_size    ≈ linear_size + 2 quadratic_size
    #   
    #   3. => quadratic_size = (domain_size - 1) * linear_size ÷ 2 [2]
    #   4. => linear_size    ≈ 2 * total_size ÷ (domain_size + 1)  [1, 3]
    linear_size    = 2 * total_size ÷ (domain_size + 1)
    quadratic_size = total_size - linear_size

    sizehint!(data[:linear_terms], linear_size)
    sizehint!(data[:quadratic_terms], quadratic_size)

    return true
end

function _parse_line!(fmt::Qubist, data::Dict{Symbol,Any}, line::AbstractString)
    _parse_entry!(fmt, data, line)  && return nothing
    _parse_header!(fmt, data, line) && return nothing

    syntax_error("'$line'")
end

function read_model(io::IO, fmt::Qubist)
    data = Dict{Symbol,Any}(
        :linear_terms    => Dict{Int,Float64}(),
        :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
    )

    for line in strip.(readlines(io))
        _parse_line!(fmt, data, line)
    end

    return Model{Int,Float64,Int}(data[:linear_terms], data[:quadratic_terms])
end
