# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

@doc raw"""
    Pegasus()
"""
struct Pegasus <: DWaveArchitecture end

function layout(arch::Pegasus)
    # TODO: Retrieve this information from dwave-networkx

    return nothing
end
