function write_model(io::IO, model::AbstractModel, fmt::HFS)
    if isempty(model)
        return write(io, "0 0")
    end

    chimera = Chimera(
        model,
        fmt.chimera_cell_size,
        fmt.chimera_degree,
        fmt.chimera_precision,
    )

    # Output the hfs data file
    # it is a header followed by linear terms and then quadratic terms
    println(io, "$(chimera.effective_degree) $(chimera.effective_degree)")

    for (i, q) in chimera.linear_terms
        args = [
            collect(chimera.coordinates[variable(model, i)])
            collect(chimera.coordinates[variable(model, i)])
            q
        ]

        Printf.@printf(io, "%2d %2d %2d %2d    %2d %2d %2d %2d    %8d\n", args...)
    end

    for ((i, j), Q) in chimera.quadratic_terms
        args = [
            collect(chimera.coordinates[variable(model, i)])
            collect(chimera.coordinates[variable(model, j)])
            Q
        ]

        Printf.@printf(io, "%2d %2d %2d %2d    %2d %2d %2d %2d    %8d\n", args...)
    end

    return nothing
end
