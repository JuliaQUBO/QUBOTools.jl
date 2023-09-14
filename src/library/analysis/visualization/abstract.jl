function Base.show(io::IO, ::V) where {V<:AbstractVisualization}
    println(io, V)

    return nothing
end
