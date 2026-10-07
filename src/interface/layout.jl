@doc raw"""
    topology(model)
    topology(form::AbstractForm)

Returns a [`Graphs.jl`](https://github.com/JuliaGraphs/Graphs.jl)-compatible graph
representing the quadratic interactions between variables in the model.
The returned `Graphs.SimpleGraph{Int}` contains every vertex in
`1:dimension(model)` (or `1:dimension(form)`), including isolated variables.
Vertex indices match form indices; use [`variable`](@ref) to recover model labels.
"""
function topology end

@doc raw"""
    adjacency(model)

An alias for [`topology`](@ref).
"""
const adjacency = topology

@doc raw"""
    geometry

Returns a ``n \times N`` matrix describing the placement of the ``n`` variable
sites in ``N``-dimensional space.
"""
function geometry end

@doc raw"""
    Layout
"""
struct Layout{N, G<:AbstractGraph}
    graph::G
    points::Vector{Point{N,Float64}}

    function Layout(graph::G, points::Vector{Point{N,Float64}}) where {G<:AbstractGraph,N}
        return new{N,G}(graph, points)
    end
end

topology(layout::Layout) = layout.graph
geometry(layout::Layout) = layout.points

@doc raw"""
    layout(::Any)
    layout(::Any, ::G) where {G<:AbstractGraph}

Returns the layout of a model, device architecture, i.e., a description of the
geometrical placement of each site as long as the network of their connections.
"""
function layout end
