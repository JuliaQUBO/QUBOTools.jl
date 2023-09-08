@doc raw"""
    HFS(;
        chimera_cell_size::Union{Integer,Nothing} = nothing,
        chimera_precision::Union{Integer,Nothing} = nothing,
        chimera_degree::Union{Integer,Nothing}    = nothing,
    )

This format offers a description for the setup of chimera graphs.
"""
struct HFS <: AbstractFormat
    chimera::Chimera

    function HFS(chimera::Chimera)
        return new(chimera)
    end
end

format(::Val{:hfs}) = HFS(Chimera())

include("printer.jl")
