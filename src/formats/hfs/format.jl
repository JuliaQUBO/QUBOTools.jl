@doc raw"""
    HFS

This format offers a description for the setup of chimera graphs.
""" struct HFS <: AbstractFormat
    chimera_cell_size::Union{Int,Nothing}
    chimera_precision::Union{Int,Nothing}
    chimera_degree::Union{Int,Nothing}

    function HFS(;
        chimera_cell_size::Union{Int,Nothing} = nothing,
        chimera_precision::Union{Int,Nothing} = nothing,
        chimera_degree::Union{Int,Nothing}    = nothing,
    )
        return new(chimera_cell_size, chimera_precision, chimera_degree)
    end
end

domain(::HFS) = BoolDomain

infer_format(::Val{:hfs}) = HFS()

include("chimera.jl")
include("parser.jl")
include("printer.jl")