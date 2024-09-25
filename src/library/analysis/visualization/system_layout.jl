struct SystemLayoutPlot{N,G<:Graphs.AbstractGraph,T} <: AbstractVisualization
    n::Integer
    layout::Layout{N,G}
    weight::SparseMatrixCSC{T,Int}

    function SystemLayoutPlot(n::Integer, layout::Layout{N,G}, weight::SparseMatrixCSC{T,Int}) where {N,G,T}
        return new{N,G,T}(n, layout, weight)
    end
end 

# Model constructor
function SystemLayoutPlot(model::M) where {V,T,U,M<:AbstractModel{V,T,U}}
    layout = QUBOTools.layout(model)

    n, L, Q, α = form(model, :sparse)
    weight = α * (Q + spdiagm(L))

    return SystemLayoutPlot(n, layout, weight)
end

# Matrix constructor
function SystemLayoutPlot(W::AbstractMatrix{T}) where {T}
    if size(W, 1) != size(W, 2)
        throw(ArgumentError("The weight matrix must be square."))
    end

    g = QUBOTools.topology(W)

    return SystemLayoutPlot(g, sparse(W))
end

# Graph-Matrix constructor
function SystemLayoutPlot(g::G, W::AbstractMatrix{T}) where {G<:AbstractGraph,T}
    n = Graphs.nv(g)

    if size(W, 1) != size(W, 2)
        throw(ArgumentError("The weight matrix must be square."))
    end

    if n != size(W, 1)
        throw(ArgumentError("The weight matrix must have the same number of rows and columns as the graph has vertices."))
    end
    
    return SystemLayoutPlot(n, QUBOTools.layout(g), sparse(W))
end

# Fallback dispatch
SystemLayoutPlot(model) = SystemLayoutPlot(backend(model))

@recipe function plot(plt::SystemLayoutPlot{2,G,T}) where {G,T}
    title      --> "System Layout"
    margin     --> (0.5, :cm)
    fontfamily --> "Computer Modern"

    g = QUBOTools.topology(plt.layout)
    P = QUBOTools.geometry(plt.layout)

    W = plt.weight
    Γ = maximum(abs, W)

    x = map(p -> p[1], P)
    y = map(p -> p[2], P)
    z = [W[i, i] for i = 1:plt.n]

    m = 3 * Graphs.ne(g)

    X = sizehint!(Float64[], m)
    Y = sizehint!(Float64[], m)
    Z = sizehint!(Float64[], m)

    for e in Graphs.edges(g)
        u = Graphs.src(e)
        v = Graphs.dst(e)

        push!(X, x[u], x[v], NaN)
        push!(Y, y[u], y[v], NaN)
        push!(Z, W[u, v], W[u, v], NaN)
    end

    pop!(X)
    pop!(Y)

    @series begin
        line_z := Z
        legend := nothing
        color --> :balance

        (X, Y)
    end

    marker_z     := z
    seriestype   := :scatter
    aspect_ratio := :equal
    markersize   := 5
    clims        := (-Γ, Γ)
    color       --> :balance
    colorbar     := true
    legend       := nothing
    grid        --> false

    return (x, y)
end