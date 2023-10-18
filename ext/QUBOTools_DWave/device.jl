# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

struct DWaveDevice{A<:DWaveArchitecture,V} <: QUBOTools.AbstractDevice{A,V,Int,Int}
    arch::A
    model::QUBOTools.Model{V,Int,Int}
    factor::Float64

    function DWaveDevice(
        arch::A,
        model::QUBOTools.Model{V,Int,Int},
        factor::Float64 = 1.0,
    ) where {A<:DWaveArchitecture,V}
        return new{A,V}(arch, model, factor)
    end
end

QUBOTools.architecture(dev::DWaveDevice) = dev.arch
QUBOTools.backend(dev::DWaveDevice)      = dev.model
