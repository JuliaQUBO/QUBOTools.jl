@doc raw"""
    HFS

This format offers a description for the setup of chimera graphs.
""" struct HFS <: AbstractFormat
    chimera_cell_size::Union{Int,Nothing}
    chimera_precision::Union{Int,Nothing}
    chimera_degree::Union{Int,Nothing}

    function HFS(
        dom::Domain                           = BoolDomain(),
        sty::Union{Style,Nothing}             = nothing;
        chimera_cell_size::Union{Int,Nothing} = nothing,
        chimera_precision::Union{Int,Nothing} = nothing,
        chimera_degree::Union{Int,Nothing}    = nothing,
    )
        supports_style(HFS, sty) || unsupported_style_error(HFS, sty)
        supports_domain(HFS, dom) || unsupported_domain_error(HFS, dom)

        return new(chimera_cell_size, chimera_precision, chimera_degree)
    end
end

domain(::HFS) = BoolDomain

supports_domain(::Type{HFS}, ::BoolDomain) = true

infer_format(::Val{:hfs}) = HFS()

include("chimera.jl")
include("parser.jl")
include("printer.jl")