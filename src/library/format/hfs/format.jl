@doc raw"""
    HFS(;
        chimera_cell_size::Union{Integer,Nothing} = nothing,
        chimera_precision::Union{Integer,Nothing} = nothing,
        chimera_degree::Union{Integer,Nothing}    = nothing,
    )

This format offers a description for the setup of chimera graphs.
"""
struct HFS <: AbstractFormat
    chimera_cell_size::Union{Int,Nothing}
    chimera_precision::Union{Int,Nothing}
    chimera_degree::Union{Int,Nothing}

    function HFS(;
        chimera_cell_size::Union{Integer,Nothing} = nothing,
        chimera_precision::Union{Integer,Nothing} = nothing,
        chimera_degree::Union{Integer,Nothing}    = nothing,
    )
        return new(chimera_cell_size, chimera_precision, chimera_degree)
    end
end

format(::Val{:hfs}) = HFS()

include("chimera.jl")
include("printer.jl")
