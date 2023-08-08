@doc raw"""
    Qubist()

"""
struct Qubist{S} <: AbstractFormat{S}
    Qubist() = new{nothing}()
end

format(::Val{:qh}) = Qubist()

include("parser.jl")
include("printer.jl")
