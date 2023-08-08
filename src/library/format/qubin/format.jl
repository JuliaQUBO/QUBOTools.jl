struct QUBin{S} <: AbstractFormat{S}
    QUBin() = new{nothing}()
end

# Hints:
format(::Val{:hdf5}) = QUBin()
format(::Val{:h5})   = QUBin()
format(::Val{:qb})   = QUBin()

include("parser.jl")
include("printer.jl")
