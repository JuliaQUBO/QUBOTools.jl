function read_model(io::IO, fmt::Qubist)
    data = Dict{Symbol,Any}(
        :linear_terms    => Dict{Int,Float64}(),
        :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
    )

    for line in readlines(io)
        _parse_line!(data, strip(line), fmt)
    end

    if !haskey(data, :dimension)
        data[:dimension] = max(
            maximum(keys(data[:linear_terms]))
            maximum(maximum, keys(data[:quadratic_terms]))
        )
    end

    return Model{Int,Float64,Int}(
        Set{Int}(1:data[:dimension]),
        data[:linear_terms],
        data[:quadratic_terms],
        sense  = :min,
        domain = :spin,
    )
end

function _parse_line!(data::Dict{Symbol,Any}, line::AbstractString, fmt::Qubist)
    isempty(line) && return nothing

    _parse_entry!(data, line, fmt) && return nothing
    _parse_header!(data, line, fmt) && return nothing

    syntax_error("'$line'")
end

function _parse_entry!(data::Dict{Symbol,Any}, line::AbstractString, ::Qubist)
    m = match(r"^\s*([0-9]+)\s+([0-9]+)\s+([+-]?([0-9]*[.])?[0-9]+)\s*$", line)

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

function _parse_header!(data::Dict{Symbol,Any}, line::AbstractString, ::Qubist)
    m = match(r"^([0-9]+)\s+([0-9]+)$", line)

    if isnothing(m)
        return false
    end

    dimension  = parse(Int, m[1])
    total_size = parse(Int, m[2])
    
    data[:dimension] = dimension

    # `sizehint!` linear and quadratic collections for dictionary pre-allocation
    # Rationale: 
    #   1. linear_size + quadratic_size = total_size
    #   2. dimension * linear_size    ≈ linear_size + 2 quadratic_size
    #   
    #   3. => quadratic_size = (dimension - 1) * linear_size ÷ 2 [2]
    #   4. => linear_size    ≈ 2 * total_size ÷ (dimension + 1)  [1, 3]
    linear_size    = 2 * total_size ÷ (dimension + 1)
    quadratic_size = total_size - linear_size

    sizehint!(data[:linear_terms], linear_size)
    sizehint!(data[:quadratic_terms], quadratic_size)

    return true
end
