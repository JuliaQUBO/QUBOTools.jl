struct Device{A,V,T,U} <: AbstractDevice{A,V,T,U}
    arch::A
    model::Model{V,T,U}
end

function backend(device::Device)
    return device.model
end
