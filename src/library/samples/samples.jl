abstract type AbstractSampleSet{T<:Real, U<:Integer} end

include("sample.jl")
include("sampleset.jl")

# ~*~ :: Metadata Validation :: ~*~ #
const SAMPLESET_METADATA_SCHEMA = JSONSchema.Schema(
    JSON.parsefile(joinpath(@__DIR__, "sampleset.schema.json"))
)

# function Base.isvalid(S::SampleSet)
#     report = JSONSchema.validate(SAMPLESET_METADATA_SCHEMA, S.metadata)

#     if !isnothing(report)
#         @warn report
#         return false
#     else
#         return true
#     end
# end