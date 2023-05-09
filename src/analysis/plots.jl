@recipe function plot(ω::AbstractSampleSet{T}) where {T}
    title  --> "Solution Summary"
    xlabel --> "Energy"
    ylabel --> "Frequency"
    legend --> nothing
    
    x = value.(ω)
    y = reads.(ω)
    n = length(y)
    z = zeros(Int, n)
    λ = nothing

    for i = 1:n
        if !isnothing(λ) && λ ≈ x[i]
            z[i] = y[i-1]
            y[i] = y[i] + z[i]
        end

        λ = x[i]
    end

    seriestype := :bar
    fillrange  := z

    return (x, y)
end

@recipe function plot(model::AbstractModel{V,T,U}) where {V,T,U}
    title  --> "Model density"
    xlabel --> "Variable Index"
    ylabel --> "Variable Index"
    color  --> :binary
    xmirror := true

    x = indices(model)
    y = reverse(x)
    z = reverse!(abs.(first(qubo(model, Matrix))); dims=1)
    
    seriestype := :heatmap

    return (x, y, z)
end
