struct ModelDensityPlot{V,T,U,M<:AbstractModel{V,T,U}} <: AbstractVisualization
    model::M

    function ModelDensityPlot(model::M) where {V,T,U,M<:AbstractModel{V,T,U}}
        return new{V,T,U,M}(model)
    end
end

function ModelDensityPlot(model::Any)
    return ModelDensityPlot(backend(model))
end

function _model_density_ticks(
    n::Integer,
    p::Integer = (n <= 16) ? n : 8,
)
    if n <= p
        return collect(Int, 1:n)
    else
        k = round(Int, n / p)

        return [1;(k+1):k:(n-k);n]
    end
end

@recipe function plot(plt::ModelDensityPlot{V,T,U,M}) where {V,T,U,M}
    title      --> "Model Density"
    color      --> :balance
    xlabel     --> "Variable Index"
    ylabel     --> "Variable Index"
    fontfamily --> "Computer Modern"

    top_margin    --> ( 0, :px)
    bottom_margin --> ( 0, :px)
    left_margin   --> (20, :px)
    right_margin  --> (20, :px)

    n, L, Q, α = form(plt.model, :dense)

    t = _model_density_ticks(n)
    z = α * (Symmetric(Q / 2) + diagm(L))
    
    Γ = maximum(abs.(z))

    xticks       := t
    yticks       := t
    clims        := (-Γ, Γ)
    yflip        := true
    xmirror      := true
    seriestype   := :heatmap
    aspect_ratio := :equal
    framestyle   := :grid
    size         := (505, 500)

    return (1:n, 1:n, collect(z))
end
