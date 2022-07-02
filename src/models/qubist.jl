@doc raw"""
""" struct Qubist{D <: SpinDomain} <: Model{D}
    sites::Int
    lines::Int
    linear_terms::Dict{Int, Float64}
    quadratic_terms::Dict{Tuple{Int, Int}, Float64}

    function Qubist{D}(
            sites::Integer,
            lines::Integer,    
            linear_terms::Dict{Int, Float64},
            quadratic_terms::Dict{Tuple{Int, Int}, Float64},
        ) where D <: SpinDomain
        new{D}(
            sites,
            lines,
            linear_terms,
            quadratic_terms,
        )
    end

    function Qubist(
            sites::Integer,    
            lines::Integer,
            linear_terms::Dict{Int, Float64},
            quadratic_terms::Dict{Tuple{Int, Int}, Float64},
        )
        Qubist{SpinDomain}(
            sites,    
            lines,
            linear_terms,
            quadratic_terms,
        )
    end
end

function Base.:(==)(x::Qubist, y::Qubist)
    (x.sites == y.sites) && (x.lines == y.lines) && (x.linear_terms == y.linear_terms) && (x.quadratic_terms == y.quadratic_terms)
end

function Base.write(io::IO, model::Qubist)
    println(io, "$(model.sites) $(model.lines)")
    for (i, h) in model.linear_terms
        println(io, "$(i) $(i) $(h)")
    end
    for ((i, j), J) in model.quadratic_terms
        println(io, "$(i) $(j) $(J)")
    end
end

function Base.read(io::IO, ::Type{<:Qubist})
    linear_terms = Dict{Int, Float64}()
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
        sites,    
        lines,
        linear_terms,
        quadratic_terms,
    )
end