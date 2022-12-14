@doc raw"""
    HFS{BoolDomain}

This format offers a description for the setup of chimera graphs.
""" struct HFS{D<:𝔹} <: AbstractFormat{D}
    chimera_cell_size::Union{Int,Nothing}
    chimera_precision::Union{Int,Nothing}
    chimera_degree::Union{Int,Nothing}

    function HFS{D}(;
        chimera_cell_size::Union{Int,Nothing} = nothing,
        chimera_precision::Union{Int,Nothing} = nothing,
        chimera_degree::Union{Int,Nothing}    = nothing,
    ) where {D}
        return new{D}(chimera_cell_size, chimera_precision, chimera_degree)
    end
end

HFS(args...; kws...) = HFS{𝔹}(args...; kws...)

infer_format(::Val{:hfs}) = HFS()

include("chimera.jl")
include("parser.jl")
include("printer.jl")