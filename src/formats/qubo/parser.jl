function _parse_line!(fmt::QUBO, data::Dict{Symbol,Any}, line::AbstractString)
    _parse_entry!(fmt, data, line, fmt.style)     && return nothing
    _parse_comment!(fmt, data, line, fmt.comment) && return nothing
    _parse_header!(fmt, data, line, fmt.style)    && return nothing

    syntax_error("$line")
end

function _parse_entry!(fmt::QUBO, data::Dict{Symbol,Any}, line::AbstractString, style::Symbol)
    return _parse_entry!(fmt, data, line, Val(style))
end

function _parse_entry!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString, ::Any)
    m = match(r"^([0-9]+) ([0-9]+) ([+-]?([0-9]*[.])?[0-9]+)$", line)

    if isnothing(m)
        return false
    end
    
    i = tryparse(Int, m[1])
    j = tryparse(Int, m[2])
    c = tryparse(Float64, m[3])

    if isnothing(i) || isnothing(j) || isnothing(c)
        syntax_error("")
    end

    if i == j
        L    = data[:linear_terms]
        L[i] = get(L, i, 0.0) + c
    else
        Q         = data[:quadratic_terms]
        Q[(i, j)] = get(Q, (i, j), 0.0) + c
    end

    return true
end

function _parse_entry!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString, ::Val{:mqlib})
    m = match(r"^([0-9]+) ([0-9]+) ([+-]?([0-9]*[.])?[0-9]+)$", line)

    if isnothing(m)
        return false
    end
    
    i = tryparse(Int, m[1])
    j = tryparse(Int, m[2])
    c = tryparse(Float64, m[3])

    if isnothing(i) || isnothing(j) || isnothing(c)
        syntax_error("")
    end

    if i == j
        L    = data[:linear_terms]
        L[i] = get(L, i, 0.0) + c
    else
        Q         = data[:quadratic_terms]
        Q[(i, j)] = get(Q, (i, j), 0.0) + 2c
    end

    return true
end

function _parse_header!(fmt::QUBO, data::Dict{Symbol,Any}, line::AbstractString, style::Symbol)
    return _parse_header!(fmt, data, line, Val(style))
end

function _parse_header!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString, ::Val{:dwave})
    m = match(r"^p qubo ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)$", line)

    if isnothing(m)
        return false
    end

    data[:domain_size]    = tryparse(Int, m[2])
    data[:linear_size]    = tryparse(Int, m[3])
    data[:quadratic_size] = tryparse(Int, m[4])

    return true
end

function _parse_header!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString, ::Val{:mqlib})
    m = match(r"^([0-9]+) ([0-9]+)$", line)

    if isnothing(m)
        return false
    end

    data[:domain_size]    = tryparse(Int, m[1])
    data[:quadratic_size] = tryparse(Int, m[2])

    return true
end

function _parse_comment!(::QUBO, ::Dict{Symbol,Any}, ::AbstractString, ::Nothing)
    return false
end

function _parse_comment!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString, comment::String)
    m = match(r"^" * comment * r"\s*(.+)?$", line)

    if isnothing(m)
        return false    
    elseif isnothing(m[1])
        return true
    end

    content = strip(m[1])

    if isempty(content)
        return true
    end

    # -*- Metadata -*-
    m = match(r"([a-zA-Z][a-zA-Z0-9_]+)\s*:\s*(.+)$", content)

    if isnothing(m)
        return true
    end

    key = string(m[1])
    val = string(m[2])

    if key == "id"
        data[:id] = tryparse(Int, val)
    elseif key == "scale"
        data[:scale] = tryparse(Float64, val)
    elseif key == "offset"
        data[:offset] = tryparse(Float64, val)
    elseif key == "description"
        data[:description] = val
    else
        data[:metadata][key] = JSON.parse(val)
    end

    return true
end

function read_model(io::IO, fmt::QUBO)
    data = Dict{Symbol,Any}(
        :linear_terms    => Dict{Int,Float64}(),
        :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
        :scale           => nothing,
        :offset          => nothing,
        :id              => nothing,
        :description     => nothing,
        :metadata        => Dict{String,Any}(),
        :domain_size     => nothing,
        :linear_size     => nothing,
        :quadratic_size  => nothing,
    )

    for line in strip.(readlines(io))
        _parse_line!(fmt, data, line)
    end

    return Model{BoolDomain,Int,Float64,Int}(
        data[:linear_terms],
        data[:quadratic_terms];
        scale       = data[:scale],
        offset      = data[:offset],
        id          = data[:id],
        description = data[:description],
        metadata    = data[:metadata],
    )
end