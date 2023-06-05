function _print_header(io::IO, data::Dict{Symbol,Any}, ::Qubist)
    dimension    = data[:dimension]
    linear_size    = data[:linear_size]
    quadratic_size = data[:quadratic_size]

    println(io, "$(dimension) $(linear_size + quadratic_size)")

    return nothing
end

function write_model(io::IO, model::AbstractModel, fmt::Qubist)
    data = Dict{Symbol,Any}(
        :dimension    => dimension(model),
        :linear_size    => linear_size(model),
        :quadratic_size => quadratic_size(model),
    )

    _print_header(io, data, fmt)

    for (i, h) in linear_terms(model)
        println(io, "$(i) $(i) $(h)")
    end

    for ((i, j), J) in quadratic_terms(model)
        println(io, "$(i) $(j) $(J)")
    end

    return nothing
end