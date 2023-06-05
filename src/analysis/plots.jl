struct EnergyFrequencyPlot{T,U,S<:AbstractSolution{T,U}} <: AbstractVisualization
    solution::S

    function EnergyFrequencyPlot(solution::S) where {T,U,S<:AbstractSolution{T,U}}
        return new{T,U,S}(solution)
    end
end

function EnergyFrequencyPlot(model::AbstractModel)
    return EnergyFrequencyPlot(solution(model))
end

function EnergyFrequencyPlot(model::Any)
    return EnergyFrequencyPlot(backend(model))
end

@recipe function f(plt::EnergyFrequencyPlot)
    title  --> "Solution Summary"
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

struct ModelDensityPlot{V,T,U,M<:AbstractModel{V,T,U}} <: AbstractVisualization
    model::M

    function ModelDensityPlot(model::M) where {V,T,U,M<:AbstractModel{V,T,U}}
        return new{V,T,U,M}(model)
    end
end

function ModelDensityPlot(model::Any)
    return ModelDensityPlot(backend(model))
end

@recipe function f(plt::ModelDensityPlot{V,T,U}) where {V,T,U}
    title  --> "Model density"
    color  --> :bwr
    xlabel --> "Variable Index"
    ylabel --> "Variable Index"

    n = dimension(plt.model)
    t = collect(1:(n÷10+1):n)

    xticks := t
    yticks := t

    z = if domain(plt.model) === nothing
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
