function _print_header(::IO, ::QUBO, ::Dict{Symbol,Any})
    return nothing
end

function _print_header(io::IO, ::QUBO{S}, data::Dict{Symbol,Any}) where {S<:DWaveStyle}
    dimension      = data[:dimension]
    linear_size    = data[:linear_size]
    quadratic_size = data[:quadratic_size]

    println(io, "p qubo 0 $(dimension) $(linear_size) $(quadratic_size)")

    return nothing
end

function _print_header(io::IO, ::QUBO{S}, data::Dict{Symbol,Any}) where {S<:MQLibStyle}
    dimension      = data[:dimension]
    linear_size    = data[:linear_size]
    quadratic_size = data[:quadratic_size]

    println(io, "$(dimension) $(linear_size + quadratic_size)")

    return nothing
end

function _print_metadata(::IO, ::QUBO, ::Dict{Symbol,Any})
    return nothing
end

function _print_metadata_entry(
    io::IO,
    ::QUBO{S},
    key::AbstractString,
    val::Any,
) where {S<:DWaveStyle}
    println(io, "c $(key) : $(val)")

    return nothing
end

function _print_metadata_entry(
    io::IO,
    ::QUBO{S},
    key::AbstractString,
    val::Any,
) where {S<:MQLibStyle}
    println(io, "# $(key) : $(val)")

    return nothing
end

function _print_metadata(io::IO, ::QUBO, data::Dict{Symbol,Any}, comment::String)
    scale    = data[:scale]
    offset   = data[:offset]
    metadata = data[:metadata]

    !isnothing(scale) && _print_metadata_entry(io, fmt, "scale", scale)
    !isnothing(offset) && _print_metadata_entry(io, fmt, "offset", offset)

    if !isnothing(metadata)
        for (key, val) in metadata
            _print_metadata_entry(io, fmt, key, val)

            print(io, "$(comment) $(key) : $(JSON.json(val))")
        end
    end

    return nothing
end

function _print_entries(io::IO, ::QUBO, data::Dict{Symbol,Any})
    for (i, l) in data[:linear_terms]
        println(io, "$(i) $(i) $(l)")
    end

    for ((i, j), q) in data[:quadratic_terms]
        println(io, "$(i) $(j) $(q)")
    end

    return nothing
end

function _print_entries(io::IO, ::QUBO{S}, data::Dict{Symbol,Any}) where {S<:DWaveStyle}
    println(io, "c linear terms")

    for (i, l) in data[:linear_terms]
        println(io, "$(i) $(i) $(l)")
    end

    println(io, "c quadratic terms")

    for ((i, j), q) in data[:quadratic_terms]
        println(io, "$(i) $(j) $(q)")
    end

    return nothing
end

function _print_entries(io::IO, ::QUBO{S}, data::Dict{Symbol,Any}) where {S<:MQLibStyle}
    println(io, "# linear terms")

    for (i, l) in data[:linear_terms]
        println(io, "$(i) $(i) $(l)")
    end

    println(io, "# quadratic terms")

    for ((i, j), q) in data[:quadratic_terms]
        # NOTE: in MQLib qubo files, quadratic coefficients
        # are halved when written to the file
        println(io, "$(i) $(j) $(q/2)")
    end

    return nothing
end

function write_model(io::IO, model::AbstractModel, fmt::QUBO)
    data = Dict{Symbol,Any}(
        :linear_terms    => linear_terms(model),
        :quadratic_terms => quadratic_terms(model),
        :linear_size     => linear_size(model),
        :quadratic_size  => quadratic_size(model),
        :scale           => scale(model),
        :offset          => offset(model),
        :metadata        => metadata(model),
        :dimension       => dimension(model),
    )

    _print_metadata(io, fmt, data)
    _print_header(io, fmt, data)
    _print_entries(io, fmt, data)

    return nothing
end
