@doc raw"""
    Qubist

""" struct Qubist <: AbstractFormat

    function Qubist(dom::Domain = SpinDomain)
        supports_domain(Qubist, dom) || unsupported_domain_error(Qubist, dom)

        return new()
    end
end

domain(::Qubist) = SpinDomain

supports_domain(::Type{Qubist}, ::Val{SpinDomain}) = true

infer_format(::Val{:qh}) = Qubist()

include("parser.jl")
include("printer.jl")