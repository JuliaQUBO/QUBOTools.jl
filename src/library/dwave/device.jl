# NOTE: This file is temporary. In the future, it should be moved to the
# DWave.jl package, so that this functionality is activated only given a
# specific context of use.

struct DWaveDevice{A<:DWaveArchitecture,V} <: QUBOTools.AbstractDevice{A,V,Int,Int}
    arch::A
    model::QUBOTools.Model{V,Int,Int}

    factor::Float64

    effective_degree::Int

    coordinates::Dict{Int,Tuple{Int,Int,Int,Int}}

    function DWaveDevice(arch::A, model::QUBOTools.AbstractModel{V,T,U}) where {A<:DWaveArchitecture,V,T,U}
        
        return new{A,V}(arch)
    end
end

QUBOTools.architecture(dev::DWaveDevice) = dev.arch
QUBOTools.backend(dev::DWaveDevice)      = dev.model

cell_size(dev::DWaveDevice) = cell_size(QUBOTools.architecture(dev))
precision(dev::DWaveDevice) = precision(QUBOTools.architecture(dev))
degree(dev::DWaveDevice)    = degree(QUBOTools.architecture(dev))
