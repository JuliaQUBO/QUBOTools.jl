@recipe function plot(ω::SampleSet{T}; kws...) where {T}
    title  --> "Solution Summary"
    xlabel --> "Energy"
    ylabel --> "Frequency"
    fill   --> 0
    legend --> nothing
    seriestype := :bar

    # n = length(ω)
    # a = ω[1].value
    # b = ω[n].value
    # m = 1000
    # σ = 0.08 * (b - a)
    # t = range(a, b, m)
    # z = zeros(T, m)

    # for i = 1:n
    #     μ = ω[i].value
    #     y = ω[i].reads

    #     for j = 1:m
    #         x = t[j]
    #         z[j] += y * exp(-((x - μ) / σ)^2)
    #     end
    # end

    # return (t, z)

    x = [s.value for s in ω]
    y = [s.reads for s in ω]

    return (x, y)
end