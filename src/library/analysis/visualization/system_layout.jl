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

# Fallback dispatch
SystemLayoutPlot(model) = SystemLayoutPlot(backend(model))

@recipe function plot(plt::SystemLayoutPlot{2,G,T}) where {G,T}
    title  --> "System Layout"
    margin --> (0.5, :cm)

    g = QUBOTools.topology(plt.layout)
    P = QUBOTools.geometry(plt.layout)

    W = plt.weight
    Γ = maximum(abs, W)

    x = map(p -> p[1], P)
    y = map(p -> p[2], P)
    z = [W[i, i] for i = 1:plt.n]


    for e in Graphs.edges(g)
        u = Graphs.src(e)
        v = Graphs.dst(e)

        @series begin
            line_z    := [W[u, v]]
            legend    := nothing
            color    --> :balance

            ([x[u], x[v]], [y[u], y[v]])
        end
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