@doc raw"""
    GenericArchitecture()

This type is used to reach fallback implementations for [`AbstractArchitecture`](@ref).
"""
struct GenericArchitecture <: AbstractArchitecture end

function architecture(::Any)
    return GenericArchitecture()
end
