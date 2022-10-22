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
    sampleset::SampleSet{T,U}
) where {A<:VariableDomain,B<:VariableDomain,U<:Integer,T}
    return SampleSet{T,U}(
        Sample{T,U}[
            Sample{T,U}(
                QUBOTools.swap_domain(A, B, sample.state),
                sample.value,
                sample.reads,
            )
            for sample in sampleset
        ],
        deepcopy(sampleset.metadata)
    )
end

function QUBOTools.state(sampleset::SampleSet, index::Integer)
    if !(1 <= index <= length(sampleset))
        error("index '$index' out of bounds [1, $(length(sampleset))]")
    end

    return sampleset[index].state
end

function QUBOTools.reads(sampleset::SampleSet)
    return sum(sample.reads for sample in sampleset)
end

function QUBOTools.reads(sampleset::SampleSet, index::Integer)
    if !(1 <= index <= length(sampleset))
        error("index '$index' out of bounds [1, $(length(sampleset))]")
    end

    return sampleset[index].reads
end

function QUBOTools.energy(sampleset::SampleSet, index::Integer)
    if !(1 <= index <= length(sampleset))
        error("index '$index' out of bounds [1, $(length(sampleset))]")
    end

    return sampleset[index].value
end

function QUBOTools.energy(Q::AbstractMatrix{T}, ψ::AbstractVector{U}) where {U<:Integer,T}
    return ψ' * Q * ψ
end

function QUBOTools.energy(h::AbstractVector{T}, J::AbstractMatrix{T}, ψ::AbstractVector{U}) where {U<:Integer,T}
    return ψ' * J * ψ + h' * ψ
end

function QUBOTools.energy(Q::Dict{Tuple{Int,Int},T}, ψ::Vector{U}) where {U<:Integer,T}
    s = zero(T)

    for ((i, j), c) in Q
        s += ψ[i] * ψ[j] * c
    end

    return s
end

function QUBOTools.energy(h::Dict{Int,T}, J::Dict{Tuple{Int,Int},T}, ψ::Vector{U}) where {U<:Integer,T}
    s = zero(T)

    for (i, c) in h
        s += ψ[i] * c
    end

    for ((i, j), c) in J
        s += ψ[i] * ψ[j] * c
    end

    return s
end

function QUBOTools.energy(L::Vector{T}, Q::Vector{T}, u::Vector{Int}, v::Vector{Int}, ψ::Vector{U}) where {U<:Integer,T}
    s = zero(T)

    for i = eachindex(L)
        s += ψ[i] * L[i]
    end

    for k = eachindex(Q)
        s += ψ[u[k]] * ψ[v[k]] * Q[k]
    end

    return s
end

function QUBOTools.adjacency(Q::Dict{Tuple{Int,Int},T}) where {T}
    A = Dict{Int,Set{Int}}()

    for (i, j) in keys(Q)
        if !haskey(A, i)
            A[i] = Set{Int}()
        end

        if i == j
            continue
        end

        if !haskey(A, j)
            A[j] = Set{Int}()
        end

        push!(A[i], j)
        push!(A[j], i)
    end

    return A
end

function QUBOTools.adjacency(Q::Dict{Tuple{Int,Int},T}, k::Integer) where {T}
    A = Set{Int}()

    for (i, j) in keys(Q)
        if i == j
            continue
        end

        if i == k
            push!(A, j)
        end

        if j == k
            push!(A, i)
        end
    end

    return A
end