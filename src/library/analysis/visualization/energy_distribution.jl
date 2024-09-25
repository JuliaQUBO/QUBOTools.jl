struct EnergyDistributionPlot{T,U,S<:AbstractSolution{T,U}} <: AbstractVisualization
    solution::S
    λ::Union{T,Nothing}

    function EnergyDistributionPlot(
        solution::S,
        λ::Union{T,Nothing} = nothing,
    ) where {T,U,S<:AbstractSolution{T,U}}
        return new{T,U,S}(solution, λ)
    end
end

function EnergyDistributionPlot(
    model::AbstractModel{V,T,U},
    λ::Union{T,Nothing} = nothing,
) where {V,T,U}
    return EnergyDistributionPlot(solution(model), λ)
end

function EnergyDistributionPlot(model::Any, λ = nothing)
    return EnergyDistributionPlot(backend(model), λ)
end

@recipe function plot(plt::EnergyDistributionPlot{T,U,S}) where {T,U,S}
    title      --> "Solution Summary"
    xlabel     --> "Solution"
    ylabel     --> "Energy"
    legend     --> :outertop
    margin     --> (0.5, :cm)
    fontfamily --> "Computer Modern"

    r = reads(plt.solution)
    x = collect(1:r)
    y = Vector{T}(undef, r)
    i = 0

    for sample in plt.solution
        v = value(sample)

        for _ = 1:reads(sample)
            y[i += 1] = v
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
        color      --> :magma
        seriestype  := :scatter
        marker      := :circle
        markerstrokewidth := 0
        colorbar    := false
        zcolor      := y
        z_order     := :back

        (x, y)
    end

    @series begin
        label      --> nothing
        color      --> :magma
        seriestype  := :line
        colorbar    := false
        line_z      := y
        z_order     := :back

        (x, y)
    end

    return nothing
end
