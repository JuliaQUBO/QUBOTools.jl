function _parse_line!(fmt::QUBO, data::Dict{Symbol,Any}, line::AbstractString)
    isempty(line) && return nothing

    _parse_entry!(fmt, data, line)   && return nothing
    _parse_comment!(fmt, data, line) && return nothing
    _parse_header!(fmt, data, line)  && return nothing

    syntax_error("$line")

    return nothing
end

function _parse_entry!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString)
    L = data[:linear_terms]
    Q = data[:quadratic_terms]
    
    m = match(r"^([0-9]+)\s+([0-9]+)\s+([+-]?([0-9]*[.])?[0-9]+)$", line)

    if isnothing(m)
        return false
    end
    
    i = parse(Int, m[1])
    j = parse(Int, m[2])
    c = parse(Float64, m[3])

    if i == j
        L[i] = get(L, i, 0.0) + c
    else
        Q[(i, j)] = get(Q, (i, j), 0.0) + c
    end

    return true
end

function _parse_entry!(::QUBO{S}, data::Dict{Symbol,Any}, line::AbstractString) where {S<:MQLibStyle}
    L = data[:linear_terms]
    Q = data[:quadratic_terms]
    
    m = match(r"^([0-9]+)\s+([0-9]+)\s+([+-]?([0-9]*[.])?[0-9]+)$", line)

    if isnothing(m)
        return false
    end
    
    i = parse(Int, m[1])
    j = parse(Int, m[2])
    c = parse(Float64, m[3])

    if i == j
        L[i] = get(L, i, 0.0) + c
    else
        # NOTE: in MQLib qubo files, quadratic coefficients
        # are halved when written to the file
        Q[(i, j)] = get(Q, (i, j), 0.0) + 2c
    end

    return true
end

function _parse_header!(::QUBO, data::Dict{Symbol,Any}, line::AbstractString)
    return false
end

function _parse_header!(::QUBO{S}, data::Dict{Symbol,Any}, line::AbstractString) where {S<:DWaveStyle}
    m = match(r"^p\s+qubo\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)$", line)

    if isnothing(m)
        return false
    end

    data[:dimension]      = parse(Int, m[2])
    data[:linear_size]    = parse(Int, m[3])
    data[:quadratic_size] = parse(Int, m[4])

    return true
end

function _parse_header!(::QUBO{S}, data::Dict{Symbol,Any}, line::AbstractString) where {S<:MQLibStyle}
    m = match(r"^([0-9]+)\s+([0-9]+)$", line)

    if isnothing(m)
        return false
    end

    data[:dimension]      = parse(Int, m[1])
    data[:quadratic_size] = parse(Int, m[2])

    return true
end

function _parse_comment!(::QUBO, ::Dict{Symbol,Any}, ::AbstractString)
    return false
end

function _parse_comment_metadata!(::QUBO, data::Dict{Symbol,Any}, content::AbstractString)
    m = match(r"^([a-zA-Z][a-zA-Z0-9_]+)\s*:\s*(.+)$", content)

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

    return nothing
end

function _parse_comment!(fmt::QUBO{S}, data::Dict{Symbol,Any}, line::AbstractString) where {S<:DWaveStyle}
    m = match(r"^c\s*(.+)?$", line)

    if isnothing(m)
        return false    
    elseif isnothing(m[1])
        return true
    end

    content = strip(m[1])

    if isempty(content)
        return true
    end

    _parse_comment_metadata!(fmt, data, content)

    return true
end

function _parse_comment!(::QUBO{S}, data::Dict{Symbol,Any}, line::AbstractString) where {S<:MQLibStyle}
    m = match(r"^\#\s*(.+)?$", line)

    if isnothing(m)
        return false    
    elseif isnothing(m[1])
        return true
    end

    content = strip(m[1])

    if isempty(content)
        return true
    end

    _parse_comment_metadata!(fmt, data, content)

    return true
end

function read_model(io::IO, fmt::QUBO)
    data = Dict{Symbol,Any}(
        :linear_terms    => Dict{Int,Float64}(),
        :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
        :scale           => 1.0,
        :offset          => 0.0,
        :id              => nothing,
        :description     => nothing,
        :metadata        => Dict{String,Any}(),
        :dimension       => nothing,
        :linear_size     => nothing,
        :quadratic_size  => nothing,
    )

    for line in readlines(io)
        _parse_line!(fmt, data, strip(line))
    end

    return Model{Int,Float64,Int}(
        data[:linear_terms],
        data[:quadratic_terms];
        scale       = data[:scale],
        offset      = data[:offset],
        sense       = :min,
        domain      = :bool,
        id          = data[:id],
        description = data[:description],
        metadata    = data[:metadata],
    )
end