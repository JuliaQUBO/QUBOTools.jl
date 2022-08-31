# ~*~ SampleSet ~*~ #

# -*- Short-circuits:
QUBOTools.swap_domain(
    ::Type{D},
    ::Type{D},
    state::Vector{U}
) where {D<:VariableDomain,U<:Integer} = state

QUBOTools.swap_domain(
    ::Type{D},
    ::Type{D},
    states::Vector{Vector{U}}
) where {D<:VariableDomain,U<:Integer} = states

QUBOTools.swap_domain(
    ::Type{D},
    ::Type{D},
    sampleset::SampleSet
) where {D<:VariableDomain} = sampleset

function QUBOTools.swap_domain(::Type{SpinDomain}, ::Type{BoolDomain}, state::Vector{U}) where {U<:Integer}
    # ~ x = (s + 1) ÷ 2 ~ #
    return (state .+ 1) .÷ 2
end

function QUBOTools.swap_domain(::Type{BoolDomain}, ::Type{SpinDomain}, state::Vector{U}) where {U<:Integer}
    # ~ s = 2x - 1 ~ #
    return (2 .* state) .- 1
end

function QUBOTools.swap_domain(
    ::Type{A},
    ::Type{B},
    states::Vector{Vector{U}}
) where {A<:VariableDomain,B<:VariableDomain,U<:Integer}
    return Vector{U}[QUBOTools.swap_domain(A, B, state) for state in states]
end

function QUBOTools.swap_domain(
    ::Type{A},
    ::Type{B},
    sampleset::SampleSet{U,T}
) where {A<:VariableDomain,B<:VariableDomain,U<:Integer,T<:Real}
    return SampleSet{U,T}(
        Sample{U,T}[
            Sample{U,T}(
                QUBOTools.swap_domain(A, B, sample.state),
                sample.reads,
                sample.value,
            )
            for sample in sampleset
        ],
        deepcopy(sampleset.metadata)
    )
end