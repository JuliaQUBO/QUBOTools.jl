@doc raw"""
    Qubist()

"""
struct Qubist{S} <: AbstractFormat{S}
    Qubist() = new{nothing}()
end

domain(::Qubist) = 𝕊

format(::Val{:qh}) = Qubist()

include("parser.jl")
include("printer.jl")