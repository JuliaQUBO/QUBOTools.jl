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
    title      --> "Model Density"
    color      --> :balance
    xlabel     --> "Variable Index"
    ylabel     --> "Variable Index"
    margin     --> (0.5, :cm)
    fontfamily --> "Computer Modern"

    n, L, Q, α = form(plt.model, :dense)

    t = collect(1:(n÷10+1):n)
    z = α * (Symmetric(Q / 2) + diagm(L))
    
    Γ = maximum(abs.(z))

    xticks       := t
    yticks       := t
    clims        := (-Γ, Γ)
    yflip        := true
    xmirror      := true
    seriestype   := :heatmap
    aspect_ratio := :equal

    return (1:n, 1:n, collect(z))
end
