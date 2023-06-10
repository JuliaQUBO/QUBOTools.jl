

struct ModelDensityPlot{V,T,U,M<:AbstractModel{V,T,U}} <: AbstractVisualization
    model::M

    function ModelDensityPlot(model::M) where {V,T,U,M<:AbstractModel{V,T,U}}
        return new{V,T,U,M}(model)
    end
end

function ModelDensityPlot(model::Any)
    return ModelDensityPlot(backend(model))
end

@recipe function plot(plt::ModelDensityPlot{V,T,U,M}) where {V,T,U,M}
    title  --> "Model density"
    color  --> :bwr
    xlabel --> "Variable Index"
    ylabel --> "Variable Index"

    n, L, Q, α, β = MatrixForm{T}(form(plt.model))

    n = dimension(plt.model)
    t = collect(1:(n÷10+1):n)
    z = Symmetric(Q / 2) + diagm(L)
    L = maximum(abs.(z))

    xticks       := t
    yticks       := t
    clims        := (-L, L)
    yflip        := true
    xmirror      := true
    seriestype   := :heatmap
    aspect_ratio := :equal

    return (1:n, 1:n, collect(z))
end
