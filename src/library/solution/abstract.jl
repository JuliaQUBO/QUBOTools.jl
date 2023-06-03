Base.size(ω::AbstractSolution) = (size(ω, 1),)

function Base.size(ω::AbstractSolution, axis::Integer)
    if axis == 1
        return length(ω)
    else
        return 1
    end
end

Base.firstindex(::AbstractSolution)            = 1
Base.firstindex(::AbstractSolution, ::Integer) = 1
Base.lastindex(ω::AbstractSolution)            = length(ω)

function Base.lastindex(ω::AbstractSolution, axis::Integer)
    if axis == 1
        return length(ω)
    elseif axis == 2 && !isempty(ω)
        return length(ω[begin])
    else
        return 1
    end
end

Base.iterate(ω::AbstractSolution) = iterate(ω, firstindex(ω))

function Base.iterate(ω::AbstractSolution, i::Integer)
    if 1 <= i <= length(ω)
        return (getindex(ω, i), i + 1)
    else
        return nothing
    end
end

function Base.show(io::IO, ω::S) where {S<:AbstractSolution}
    if isempty(ω)
        return println(io, "Empty $(S)")
    end

    println(io, "$(S) with $(length(ω)) samples:")

    for (i, s) in enumerate(ω)
        print(io, "  ")

        if i < 10
            println(io, s)
        else
            return println(io, "⋮")
        end
    end

    return nothing
end

state(ω::AbstractSolution, i::Integer)             = state(ω[i])
state(ω::AbstractSolution, i::Integer, j::Integer) = state(ω[i], j)
value(ω::AbstractSolution, i::Integer)             = value(ω[i])
reads(ω::AbstractSolution, i::Integer)             = reads(ω[i])
reads(ω::AbstractSolution)                         = sum(reads.(ω))
