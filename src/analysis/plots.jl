@recipe function plot(ω::SampleSet)
    title  --> "Solution Summary"
    xlabel --> "Energy"
    ylabel --> "Frequency"
    legend --> nothing
    
    seriestype := :bar

    x = [s.value for s in ω]
    y = [s.reads for s in ω]

    return (x, y)
end