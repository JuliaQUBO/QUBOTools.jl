function _print_header(::IO, ::QUBO, ::Dict{Symbol,Any}, ::Nothing)
    return nothing
end

function _print_header(io::IO, ::QUBO, data::Dict{Symbol,Any}, ::DWaveStyle)
    domain_size    = data[:domain_size]
    linear_size    = data[:linear_size]
    quadratic_size = data[:quadratic_size]

    println(io, "p qubo 0 $(domain_size) $(linear_size) $(quadratic_size)")

    return nothing
end

function _print_header(io::IO, ::QUBO, data::Dict{Symbol,Any}, ::MQLibStyle)
    domain_size    = data[:domain_size]
    linear_size    = data[:linear_size]
    quadratic_size = data[:quadratic_size]

    println(io, "$(domain_size) $(linear_size + quadratic_size)")

    return nothing
end

function _print_metadata(::IO, ::QUBO, ::Dict{Symbol,Any}, ::Nothing)
    return nothing
end

function _print_metadata(io::IO, ::QUBO, data::Dict{Symbol,Any}, comment::String)
    scale       = data[:scale]
    offset      = data[:offset]
    id          = data[:id]
    description = data[:description]
    metadata    = data[:metadata]

    !isnothing(scale)       && println(io, "$(comment) scale : $(scale)")
    !isnothing(offset)      && println(io, "$(comment) offset : $(offset)")
    !isnothing(id)          && println(io, "$(comment) id : $(id)")
    !isnothing(description) && println(io, "$(comment) description : $(description)")

    if !isnothing(metadata)
        for (key, val) in metadata
            print(io, "$(comment) $(key) : ")
            JSON.print(io, val)
            println(io)
        end
    end

    return nothing
end

function _print_entries(io::IO, fmt::QUBO, data::Dict{Symbol,Any}, ::Union{DWaveStyle,Nothing})
    !isnothing(fmt.comment) && println(io, "$(fmt.comment) linear terms")

    for (i, l) in data[:linear_terms]
        println(io, "$(i) $(i) $(l)")
    end

    !isnothing(fmt.comment) && println(io, "$(fmt.comment) quadratic terms")

    for ((i, j), q) in data[:quadratic_terms]
        println(io, "$(i) $(j) $(q)")
    end

    return nothing
end

function _print_entries(io::IO, fmt::QUBO, data::Dict{Symbol,Any}, ::MQLibStyle)
    !isnothing(fmt.comment) && println(io, "$(fmt.comment) linear terms")

    for (i, l) in data[:linear_terms]
        println(io, "$(i) $(i) $(l)")
    end

    !isnothing(fmt.comment) && println(io, "$(fmt.comment) quadratic terms")

    for ((i, j), q) in data[:quadratic_terms]
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
        :id              => id(model),
        :description     => description(model),
        :metadata        => metadata(model),
        :domain_size     => domain_size(model),
    )

    _print_metadata(io, fmt, data, fmt.comment)
    _print_header(io, fmt, data, style(fmt))
    _print_entries(io, fmt, data, style(fmt))
    
    return nothing
end
