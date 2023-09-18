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

    if !isnothing(plt.λ)
        @series begin
            label         --> "Energy Threshold"
            color         --> :gray
            seriestype     := :vline
            linestyle      := :dash
            colorbar_entry := :false
            z_order        := :front

            ([plt.λ],)
        end
    end

    @series begin
        label      --> nothing
        linewidth  --> 0
        color      --> :redblue
        seriestype  := :bar
        fillrange   := z
        colorbar    := false
        fill_z      := y
        z_order     := :back

        (x, y)
    end

    return nothing
end
