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

function bridges()
    G = Dict{Type,Set{Type}}()
    M = subtypes(AbstractQUBOModel)
    D = subtypes(VariableDomain)

    supports_domain(_M, _D) = (_M{<:_D} <: _M)

    for X in M, Y in M, A in D, B in D
        if supports_domain(X, A) && supports_domain(Y, B) && hasbridge(X{A}, Y{B})
            if !haskey(G, Y{B})
                G[Y{B}] = Set{Type}()
            end

            push!(G[Y{B}], X{A})
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