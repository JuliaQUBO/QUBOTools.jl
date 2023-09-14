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
    n = length(plt.solution)
    z = zeros(Int, n)

    for i = 2:n
        # Since values are sorted, if two consecutive ones
        # are approximate, we are stacking them together 
        if x[i] ≈ x[i-1]
            x[i] = x[i-1]
            z[i] = y[i-1]
            y[i] += z[i]
        end
    end

    @series begin
        # linewidth  --> 1.0
        seriestype  := :bar
        fillrange   := z
        # color      --> :green
        # colorbar    := true
        # bar_width --> 2.0

        (x, y)
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

    return nothing
end
