struct EnergyFrequencyPlot{T,U,S<:AbstractSolution{T,U}} <: AbstractVisualization
    solution::S
    λ::Union{T,Nothing}

    function EnergyFrequencyPlot(
        solution::S,
        λ::Union{T,Nothing} = nothing,
    ) where {T,U,S<:AbstractSolution{T,U}}
        return new{T,U,S}(solution, λ)
    end
end

function EnergyFrequencyPlot(
    model::AbstractModel{V,T,U},
    λ::Union{T,Nothing} = nothing,
) where {V,T,U}
    return EnergyFrequencyPlot(solution(model), λ)
end

function EnergyFrequencyPlot(model::Any, λ = nothing)
    return EnergyFrequencyPlot(backend(model), λ)
end

@recipe function plot(plt::EnergyFrequencyPlot{T,U,S}) where {T,U,S}
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

    if !isnothing(plt.λ)
        @series begin
            legend     --> "Ground Energy"
            color      --> :red
            seriestype :=  :vline
            linestyle  :=  :dash

            ([plt.λ],)
        end
    end

    linewidth  --> 1.0
    seriestype  := :bar
    fillrange   := z
    color      --> :green
    # colorbar    := true
    
    return (x, y)
end
