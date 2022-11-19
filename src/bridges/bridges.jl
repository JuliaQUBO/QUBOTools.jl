@doc raw"""
    bridge(::Type{A}, ::B)::A where {A<:AbstractQUBOModel,B<:AbstractQUBOModel}
""" function bridge end

@doc raw"""
    hasbridge(::Type{A}, ::Type{B})::Bool where {A<:AbstractQUBOModel,B<:AbstractQUBOModel} 

Tells if there is a bridge from model type `B` to model type `A`.
"""
function hasbridge(::Type{A}, ::Type{B}) where {A<:AbstractQUBOModel,B<:AbstractQUBOModel}
    return hasmethod(bridge, (Type{A}, B))
end

models() = [m{d} for m in subtypes(AbstractQUBOModel), d in subtypes(VariableDomain) if m{<:d} <: m]

function bridges()
    G = Dict{Type,Set{Type}}()
    M = models()

    for X in M, Y in M
        if hasbridge(X, Y)
            if !haskey(G, Y)
                G[Y] = Set{Type}()
            end

            push!(G[Y], X)
        end
    end

    return G
end

function chain(::Type{A}, model::B) where {A<:AbstractQUBOModel,B<:AbstractQUBOModel}
    path = findchain(A, B)

    if isnothing(path)
        codec_error("Can't convert '$B' model to '$A' by chaining bridges")
    end

    for M in path
        model = bridge(M, model)
    end

    return model
end

@doc raw"""
    findchain(::Type{A}, ::Type{B}) where {A<:AbstractQUBOModel,B<:AbstractQUBOModel}

Returns a chain i.e. a path from `B` to `A` or `nothing` if no path is available.

!!! info
    The conversion path is determined by a breadth-first-search (BFS).
""" function findchain end

function findchain(::Type{A}, ::Type{B}) where {A<:AbstractQUBOModel,B<:AbstractQUBOModel}
    visited = Set{Type}() 
    queue   = Vector{Type}[]
    graph   = bridges()

    push!(queue, Type[B])

    while !isempty(queue)
        path = popfirst!(queue)
        node = path[end]

        if node === A
            return path[2:end]
        elseif node ∉ visited
            for next in graph[node]
                push!(queue, [path; next])
            end

            push!(visited, node)
        end
    end

    return nothing
end