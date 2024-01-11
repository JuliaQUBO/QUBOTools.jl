function layout(device::AbstractDevice{A}) where {A}
    return layout(architecture(device))
end
