@doc raw"""
    GenericDevice

A thin wrapper around a [`Model`](@ref) that fulfills the [`AbstractDevice`](@ref) interface.
"""
struct GenericDevice{V,T,U} <: AbstractDevice{GenericArchitecture,V,T,U}
    model::Model{V,T,U}

    function GenericDevice{V,T,U}(model::Model{V,T,U}) where {V,T,U}
        return new{V,T,U}(model)
    end
end

function GenericDevice(model::Model{V,T,U}) where {V,T,U}
    return GenericDevice{V,T,U}(model)
end

backend(device::GenericDevice) = device.model
