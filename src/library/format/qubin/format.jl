@doc raw"""
    Format{:qubin}()

HDF5-based reference format for storing QUBOTools models and solutions.
"""
const qubin_fmt = Format{:qubin}

Format{:qubin}() = Format{:qubin}(Dict{Symbol,Any}())

# Hints:
infer_format(::Val{:hdf5}) = Format{:qubin}()
infer_format(::Val{:h5})   = Format{:qubin}()
infer_format(::Val{:qb})   = Format{:qubin}()

include("parser.jl")
include("printer.jl")
