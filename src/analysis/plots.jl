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

    n = domain_size(model)
    t = collect(1:(n ÷ 10 + 1):n)

    xticks := t
    yticks := t

    z = if domain(model) === nothing # assume its QUBO
        error("No domain specified")
    elseif domain(model) === 𝔹
        Q, = qubo(model, Symmetric)

        Q
    elseif domain(model) === 𝕊
        h, J = ising(model, Symmetric)

        J + Diagonal(h)
    else # unknown domain
        error("Unknown domain '$(domain(model))'")
    end
    
    L = maximum(abs.(z))
    
    clims        := (-L, L)
    yflip        := true
    xmirror      := true
    seriestype   := :heatmap
    aspect_ratio := :equal

    return (1:n, 1:n, collect(z))
end
