# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

module DWave

import ..QUBOTools

@doc raw"""
    DWaveArchitecture
"""
abstract type DWaveArchitecture <: QUBOTools.AbstractArchitecture end

@doc raw"""
    cell_size
"""
function cell_size end

@doc raw"""
    precision
"""
function precision end

@doc raw"""
    degree
"""
function degree end

include("device.jl")
include("chimera.jl")

end