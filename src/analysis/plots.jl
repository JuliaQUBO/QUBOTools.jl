struct SolutionDistributionPlot{T,U}
    solution::Any

    function SolutionDistributionPlot{T,U}(solution::AbstractSolution{T,U}) where {T,U}
        return new{T,U}(solution)
    end
end

SolutionDistributionPlot(model) = SolutionDistributionPlot(solution(model))

@recipe function f(plt::SolutionDistributionPlot{T,U}) where {T,U}
    title --> "Solution Summary"
    xlabel --> "Energy"
    ylabel --> "Frequency"
    legend --> nothing

    x = value.(plt.solution)
    y = reads.(plt.solution)
    n = length(y)
    z = zeros(Int, n)
    λ = nothing

    for i = 1:n
        # Since values are sorted, if two consecutive ones
        # are approximate, we are stacking them together 
        if λ !== nothing && λ ≈ x[i]
            z[i] = y[i-1]
            y[i] = y[i] + z[i]
        end

        λ = x[i]
    end

    seriestype := :bar
    fillrange  := z

    return (x, y)
end

struct ModelDensityPlot{V,T,U}
    model::Any

    function ModelDensityPlot{V,T,U}(model::AbstractModel{V,T,U}) where {V,T,U}
        return new{V,T,U}(model)
    end
end

ModelDensityPlot(model) = ModelDensityPlot(backend(model))

@recipe function f(plt::ModelDensityPlot{V,T,U}) where {V,T,U}
    title --> "Model density"
    color --> :bwr
    xlabel --> "Variable Index"
    ylabel --> "Variable Index"

    n = domain_size(plt.model)
    t = collect(1:(n÷10+1):n)

    xticks := t
    yticks := t

    z = if domain(plt.model) === nothing # assume its QUBO
        error("No domain specified")
    elseif domain(plt.model) === 𝔹
        Q, = qubo(plt.model, Symmetric)

        Q
    elseif domain(plt.model) === 𝕊
        h, J = ising(plt.model, Symmetric)

        J + Diagonal(h)
    else # unknown domain
        error("Unknown domain '$(domain(plt.model))'")
    end

    L = maximum(abs.(z))

    clims        := (-L, L)
    yflip        := true
    xmirror      := true
    seriestype   := :heatmap
    aspect_ratio := :equal

    return (1:n, 1:n, collect(z))
end
