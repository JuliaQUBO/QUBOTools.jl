# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

module DWave

import Graphs
import ..QUBOTools

@doc raw"""
    DWaveArchitecture
"""
abstract type DWaveArchitecture <: QUBOTools.AbstractArchitecture end

include("device.jl")
include("chimera.jl")
include("hfs/format.jl")

end