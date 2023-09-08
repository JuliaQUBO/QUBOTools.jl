struct SystemLayoutPlot{V,T,U,M<:AbstractModel{V,T,U}} <: AbstractVisualization
    model::M

    function SystemLayoutPlot(model::M) where {V,T,U,M<:AbstractModel{V,T,U}}
        return new{V,T,U,M}(model)
    end
end

function SystemLayoutPlot(model::Any)
    return SystemLayoutPlot(backend(model))
end

@recipe function plot(plt::SystemLayoutPlot{V,T,U,M}) where {V,T,U,M}
    title --> "System Layout"
    size  --> (500, 500)

    n, L, _, α = QUBOTools.form(plt.model)

    G = QUBOTools.topology(plt.model)
    ℓ = QUBOTools.layout(plt.model, G)

    x = first.(ℓ)
    y = last.(ℓ)
    z = [L[i] for i = 1:n]

    for e in Graphs.edges(G)
        u = Graphs.src(e)
        v = Graphs.dst(e)

        @series begin
            color  := :gray
            legend := nothing

            ([x[u], x[v]], [y[u], y[v]])
        end
    end

    zcolor       := α * z
    seriestype   := :scatter
    colorbar     := true
    aspect_ratio := :equal
    legend       := nothing
    markersize   := 5
    grid        --> false

    return (x, y)
end