@doc raw"""
    Qubist

""" struct Qubist <: AbstractFormat

    function Qubist(
        dom::SpinDomain = SpinDomain(),
        sty::Nothing    = nothing,
    )
        return new()
    end
end

domain(::Qubist) = SpinDomain()

supports_domain(::Type{Qubist}, ::SpinDomain) = true

infer_format(::Val{:qh}) = Qubist(𝕊, nothing)

include("parser.jl")
include("printer.jl")