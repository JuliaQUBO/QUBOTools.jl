# ~*~ SampleSet ~*~ #
function QUBOTools.swap_sense(source::Symbol, target::Symbol, sampleset::SampleSet{U,T}) where {U,T}
    @assert source === :min || source === :max
    @assert target === :min || target === :max

    if source === target
        return sampleset
    else
        return SampleSet{U,T}(
            Sample{U,T}[
                Sample{U,T}(sample.state, sample.reads, -sample.value)
                for sample in sampleset
            ],
            sampleset.metadata
        )
    end
end

function QUBOTools.swap_domain(source::Symbol, target::Symbol, sampleset::SampleSet{U,T}) where {U,T}
    @assert source === :bool || source === :spin
    @assert target === :bool || target === :spin

    if source === target
        return sampleset
    elseif source === :bool && target === :spin
        return SampleSet{U,T}(
            Sample{U,T}[
                Sample{U,T}((2 * sample.state) .- 1, sample.reads, sample.value)
                for sample in sampleset
            ],
            sampleset.metadata
        )
    elseif source === :spin && target === :bool
        return SampleSet{U,T}(
            Sample{U,T}[
                Sample{U,T}((sample.state .+ 1) ÷ 2, sample.reads, sample.value)
                for sample in sampleset
            ],
            sampleset.metadata
        )
    else
        error("This is not supposed to happen")
    end
end