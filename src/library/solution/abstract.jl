# States

# Samples
state(s::AbstractSample, i::Integer) = getindex(state(s), i)

# Solutions
Base.size(sol::AbstractSolution) = (size(sol, 1),)

# Comparison
function Base.:(==)(x::S, y::S) where {T,U,S<:AbstractSample{T,U}}
    return value(x) == value(y) && reads(x) == reads(y) && state(x) == state(y)
end

function Base.isapprox(x::S, y::S; kws...) where {T,U,S<:AbstractSample{T,U}}
    return isapprox(value(x), value(y); kws...) &&
           reads(x) == reads(y) &&
           state(x) == state(y)
end

function Base.size(sol::AbstractSolution, axis::Integer)
    if axis == 1
        return length(sol)
    else
        return 1
    end
end

Base.firstindex(::AbstractSolution)            = 1
Base.firstindex(::AbstractSolution, ::Integer) = 1
Base.lastindex(sol::AbstractSolution)          = length(sol)

function Base.lastindex(sol::AbstractSolution, axis::Integer)
    if axis == 1
        return length(sol)
    elseif axis == 2 && !isempty(sol)
        return length(getindex(sol, 1))
    else
        return 1
    end
end

Base.iterate(sol::AbstractSolution) = iterate(sol, firstindex(sol))

function Base.iterate(sol::AbstractSolution, i::Integer)
    if 1 <= i <= length(sol)
        return (getindex(sol, i), i + 1)
    else
        return nothing
    end
end

function Base.show(io::IO, sol::S) where {S<:AbstractSolution}
    if isempty(sol)
        return println(io, "Empty $(S)")
    end

    println(io, "$(S) with $(length(sol)) samples:")

    for (i, s) in enumerate(sol)
        print(io, "  ")

        if i < 10
            println(io, s)
        else
            return println(io, "⋮")
        end
    end

    return nothing
end

state(sol::AbstractSolution, i::Integer)             = state(getindex(sol, i))
state(sol::AbstractSolution, i::Integer, j::Integer) = state(getindex(sol, i), j)
value(sol::AbstractSolution, i::Integer)             = value(getindex(sol, i))
reads(sol::AbstractSolution, i::Integer)             = reads(getindex(sol, i))
reads(sol::AbstractSolution)                         = sum(reads.(sol))
