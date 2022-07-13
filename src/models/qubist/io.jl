function Base.write(io::IO, model::Qubist)
    println(io, "$(model.sites) $(model.lines)")
    for (i, h) in model.backend.linear_terms
        println(io, "$(i) $(i) $(h)")
    end
    for ((i, j), J) in model.backend.quadratic_terms
        println(io, "$(i) $(j) $(J)")
    end
end

function Base.read(io::IO, ::Type{<:Qubist})
    linear_terms = Dict{Int,Float64}()
    quadratic_terms = Dict{Tuple{Int,Int},Float64}()
    sites = nothing
    lines = nothing

    line = strip(readline(io))

    m = match(r"^([0-9]+)\s+([0-9]+)$", line)
    if !isnothing(m)
        sites = tryparse(Int, m[1])
        lines = tryparse(Int, m[2])
    else
        error("Error: Invalid file header")
    end

    if isnothing(sites) || isnothing(lines)
        error("Error: Invalid file header")
    end

    for line in strip.(readlines(io))
        m = match(r"^([0-9]+)\s+([0-9]+)\s+([+-]?([0-9]*[.])?[0-9]+)$", line)
        if !isnothing(m)
            i = tryparse(Int, m[1])
            j = tryparse(Int, m[2])
            q = tryparse(Float64, m[3])
            if isnothing(i) || isnothing(j) || isnothing(q)
                error("Error: invalid input '$line'")
            elseif i == j
                linear_terms[i] = get(linear_terms, i, 0.0) + q
            else
                quadratic_terms[(i, j)] = get(quadratic_terms, (i, j), 0.0) + q
            end
        else
            error("Error: invalid input '$line'")
        end
    end

    Qubist{SpinDomain}(
        linear_terms,
        quadratic_terms,
        sites,
        lines,
    )
end