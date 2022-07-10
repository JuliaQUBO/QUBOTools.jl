@doc raw"""
""" struct Qubist{D <: SpinDomain} <: AbstractBQPModel{D}
    backend::StandardBQPModel{Int, Int, Float64, D}
    sites::Int
    lines::Int

    function Qubist{D}(
            backend::StandardBQPModel{Int, Int, Float64, D},
            sites::Integer,
            lines::Integer,
        ) where D <: SpinDomain
        new{D}(backend, sites, lines)
    end

    function Qubist{D}(
            linear_terms::Dict{Int, Float64},
            quadratic_terms::Dict{Tuple{Int, Int}, Float64},
            sites::Integer,
            lines::Integer,    
        ) where D <: SpinDomain
        variable_map = build_varmap(linear_terms, quadratic_terms)
        backend      = StandardBQPModel{Int, Int, Float64, D}(
            linear_terms,
            quadratic_terms,
            0.0,
            1.0,
            variable_map,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
        )
        Qubist{D}(backend, sites, lines)
    end

    function Qubist(args...)
        Qubist{SpinDomain}(args...)
    end
end

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
    linear_terms    = Dict{Int, Float64}()
    quadratic_terms = Dict{Tuple{Int, Int}, Float64}()

    sites, lines = let m = match(r"([0-9]+) ([0-9]+)", readline(io))
        if !isnothing(m)
            s = tryparse(Int, m[1])
            l = tryparse(Int, m[2])
            if isnothing(s) || isnothing(l)
                error()
            else
                (s, l)
            end
        else
            error()
        end
    end

    for line in readlines(io)
        let m = match(r"([0-9]+) ([0-9]+) ([+-]?([0-9]*[.])?[0-9]+)", line)
            if !isnothing(m)
                i = tryparse(Int, m[1])
                j = tryparse(Int, m[2])
                J = tryparse(Float64, m[3])
                if isnothing(i) || isnothing(j) || isnothing(J)
                    error()
                elseif i == j
                    linear_terms[i] = get(linear_terms, i, 0.0) + J
                elseif i < j
                    quadratic_terms[(i, j)] = get(quadratic_terms, (i, j), 0.0) + J
                else
                    quadratic_terms[(j, i)] = get(quadratic_terms, (j, i), 0.0) + J
                end
            else
                error()
            end
        end
    end

    Qubist{SpinDomain}(
        linear_terms,
        quadratic_terms,
        sites,    
        lines,
    )
end