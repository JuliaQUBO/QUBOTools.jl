function write_model(io::IO, model::AbstractModel, fmt::HFS)
    if isempty(model)
        return write(io, "0 0")
    end

    chimera = Chimera(model, fmt)

    # Output the hfs data file
    # it is a header followed by linear terms and then quadratic terms
    println(io, "$(chimera.effective_degree) $(chimera.effective_degree)")

    for (i, q) in chimera.linear_terms
        args = [
            collect(chimera.coordinates[variable_inv(model, i)]);
            collect(chimera.coordinates[variable_inv(model, i)]);
            q
        ]

        @printf("%2d %2d %2d %2d    %2d %2d %2d %2d    %8d\n", args...)
    end

    for ((i, j), Q) in chimera.quadratic_terms
        args = [
            collect(chimera.coordinates[variable_inv(model, i)]);
            collect(chimera.coordinates[variable_inv(model, j)]);
            Q
        ]

        @sprintf("%2d %2d %2d %2d    %2d %2d %2d %2d    %8d\n", args...)
    end

    return nothing
end
