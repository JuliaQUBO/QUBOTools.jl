@doc raw"""
""" struct Sample{U<:Integer, T<:Real}
    state::Vector{U}
    reads::Int
    value::T
end

function Base.:(==)(x::Sample{U, T}, y::Sample{U, T}) where {U, T}
    x.value == y.value &&
    x.reads == y.reads &&
    x.state == y.state
end

@doc raw"""
    SampleSet{U, T}(
        samples::Vector{Sample{U, T}},
        metadata::Dict{String, Any},
    ) where {U, T}

The SampleSet is intended to be read-only.
It compresses repeated states by adding up the `reads` field.
It was clearly inspired by [1], with a few tweaks.

## Ideas
1. Build Plot Recipes for this type in order to generate sampling barplots.
2. Export to compressed ASCII JSON format.

## References
[1] https://docs.ocean.dwavesys.com/en/stable/docs_dimod/reference/sampleset.html#dimod.SampleSet
""" struct SampleSet{U<:Integer, T<:Real}
    samples::Vector{Sample{U, T}}
    metadata::Dict{String, Any}

    function SampleSet{U, T}(
            data::Vector{Sample{U, T}},
            metadata::Union{Dict{String, Any}, Nothing} = nothing,
            ) where {U, T}
        # ~*~ Compress samples ~*~
        mapping = Dict{Vector{U}, Sample{U, T}}()

        for sample::Sample{U, T} in data
            cached = get(mapping, sample.state, nothing)

            if isnothing(cached)
                mapping[sample.state] = sample
            else
                @assert cached.state == sample.state
                @assert cached.value == sample.value
            
                mapping[sample.state] = Sample{U, T}(
                    sample.state,
                    sample.reads + cached.reads,
                    sample.value,
                )
            end
        end

        samples = sort(
            collect(values(mapping));
            by=(sample)->(sample.value, -sample.reads),
        )

        if isnothing(metadata)
            metadata = Dict{String, Any}()
        end

        new{U, T}(samples, metadata)
    end
end

function Base.copy(sampleset::SampleSet{U, T}) where {U, T}
    SampleSet{U, T}(copy(sampleset.samples))
end

function Base.length(X::SampleSet)
    length(X.samples)
end

function Base.:(==)(X::SampleSet{U, T}, Y::SampleSet{U, T}) where {U, T}
    length(X) == length(Y) && all(X.samples .== Y.samples)
end

# ~*~ Experimental: ASCII JSON state compression ~*~ #

# ~ Compression ~
const __COMPRESSION_TABLE = UInt8['+';'-';'0':'9';'A':'Z';'a':'z']
@assert length(__COMPRESSION_TABLE) == 64

function __COMPRESS(i::Integer)
    __COMPRESSION_TABLE[i+1]
end

function __compress(x::Vector{U}) where U
    n = length(x)
    m = n ÷ 6
    k = n % 6
    u = Vector{UInt8}(undef, m+2)

    for i = 1:m+1
        l = 0
        for j = 1:(i <= m ? 6 : k)
            l += x[6 * (i - 1) + j] << (j - 1)
        end
        u[i] = __COMPRESS(l)
    end

    u[end] = __COMPRESS(k)

    s = String(u)

    return s
end

function __compress(x::Vector{U}, ::Type{<:BoolDomain}) where U <: Integer
    __compress(x)
end

function __compress(x::Vector{U}, ::Type{<:SpinDomain}) where U <: Integer
    (__compress(x) .+ 1) .>> 1
end

function __compress(sample::Sample)
    __compress(sample.state) => (sample.reads, sample.value)
end

function __compress(sampleset::SampleSet)
    Dict{String, Any}(
        "samples"  => Dict{String, Any}(__compress(sample) for sample in sampleset.samples),
        "metadata" => sampleset.metadata,
    )
end

# ~ Uncompression ~
const __UNCOMPRESSION_MISS = UInt8('.')

function __UNCOMPRESSION_FUNC(x::Char)
    if x == '+'
        0x01
    elseif x == '-'
        0x02
    elseif '0' <= x <= '9'
        0x03 + UInt8(x - '0')
    elseif 'A' <= x <= 'Z'
        0x0d + UInt8(x - 'A')
    elseif 'a' <= x <= 'z'
        0x27 + UInt8(x - 'a')
    else
        __UNCOMPRESSION_MISS
    end
end

const __UNCOMPRESSION_TABLE = __UNCOMPRESSION_FUNC.(Char.(1:126))

function __UNCOMPRESS(i::UInt8)
    j = __UNCOMPRESSION_TABLE[i]
    @assert j != __UNCOMPRESSION_MISS
    return j - 0x01
end

function __uncompress(s::String, U::Type{<:Integer} = Int)
    u = UInt8.(collect(s))
    m = length(u) - 2
    k = __UNCOMPRESS(u[end])
    x = Vector{U}(undef, 6 * m + k)

    for i = 1:m+1
        l = __UNCOMPRESS(u[i])
        for j = 1:(i <= m ? 6 : k)
            x[6 * (i - 1) + j] = l & 0x01 # mod 2
            l = l >> 1
        end
    end

    return x
end

function __uncompress(s::String, ::Type{<:BoolDomain}, U::Type{<:Integer} = Int)
    __uncompress(s, U)
end

function __uncompress(s::String, ::Type{<:SpinDomain}, U::Type{<:Integer} = Int)
    2 * __uncompress(s, U) .- 1
end

function __uncompress(data::Dict{String, Any}, D::Type{<:VariableDomain}, U::Type{<:Integer}, T::Type{<:Real})
    SampleSet{U, T}(
        Sample{U, T}[
            Sample{U, T}(__uncompress(s, D, U), reads, convert(T, value))
            for (s, (reads, value)) in data["samples"]
        ],
        data["metadata"],
    )
end