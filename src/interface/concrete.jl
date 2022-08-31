# ~*~ SampleSet ~*~ #
function QUBOTools.swap_domain(::Type{D}, ::Type{D}, sampleset::SampleSet) where {D<:VariableDomain}
    return sampleset
end

function QUBOTools.swap_domain(::Type{SpinDomain}, ::Type{BoolDomain}, sampleset::SampleSet{U,T}) where {U,T}
    return SampleSet{U,T}(
        Sample{U,T}[
            Sample{U,T}(
                # ~ x = (s + 1) ÷ 2 ~ #
                (sample.state .+ 1) .÷ 2,
                sample.reads,
                sample.value,
            )
            for sample in sampleset
        ],
        deepcopy(sampleset.metadata)
    )
end

function QUBOTools.swap_domain(::Type{BoolDomain}, ::Type{SpinDomain}, sampleset::SampleSet{U,T}) where {U,T}
    return SampleSet{U,T}(
        Sample{U,T}[
            Sample{U,T}(
                # ~ s = 2x - 1 ~ #
                (2 .* sample.state) .- 1,
                sample.reads,
                sample.value,
            )
            for sample in sampleset
        ],
        deepcopy(sampleset.metadata)
    )
end