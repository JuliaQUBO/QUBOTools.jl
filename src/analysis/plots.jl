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
    color  --> :bwr
    xmirror := true
    
    n = domain_size(model)
    x = y = (1:n)
    z = reverse!((first(qubo(model, Matrix))); dims=1)
    clims  --> (-maximum(z), maximum(z))
    
    seriestype := :heatmap

    return (x, y, z)
end
