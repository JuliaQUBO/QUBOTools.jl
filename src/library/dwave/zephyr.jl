# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

@doc raw"""
    Zephyr()
"""
struct Zephyr <: DWaveArchitecture end

function layout(arch::Zephyr)
    # TODO: Retrieve this information from dwave-networkx

    return nothing
end
