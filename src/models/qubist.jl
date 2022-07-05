@doc raw"""
""" struct Qubist{D <: SpinDomain} <: AbstractBQPModel{D}
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
        model = new{D}(
            sites,
            lines,
            linear_terms,
            quadratic_terms,
        )

        if isvalid(model)
            model
        else
            error()
        end
    end

    function Qubist(args...)
        Qubist{SpinDomain}(args...)
    end
end

function Base.isvalid(model::Qubist)
    if model.sites < 0
        @error "Negative number of sites"
        return false
    end

    if model.lines < 0
        @error "Negative number of lines"
        return false
    end

    for (i, _) in model.linear_terms
        if i < 0
            @error "Invalid linear term $i with negative index"
            return false
        end
    end

    for ((i, j), _) in model.quadratic_terms
        if i < 0 || j < 0
            @error "Invalid quadratic term ($(i), $(j)) with negative index"
            return false
        end
    end

    return true
end

function Base.isapprox(x::Qubist, y::Qubist; kw...)
    isapprox_dict(x.linear_terms   , y.linear_terms   ; kw...) &&
    isapprox_dict(x.quadratic_terms, y.quadratic_terms; kw...)
end

function Base.:(==)(x::Qubist, y::Qubist)
    x.sites           == y.sites        &&
    x.lines           == y.lines        &&
    x.linear_terms    == y.linear_terms &&
    x.quadratic_terms == y.quadratic_terms
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
        sites,    
        lines,
        linear_terms,
        quadratic_terms,
    )
end