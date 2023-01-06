Style(sty::Style)          = sty
Style(sty::Symbol)         = Style(Val(sty))
Style(sty::AbstractString) = Style(Symbol(sty))

macro style_str(sty)
    return Style(sty)
end

function style(::AbstractFormat)
    return nothing
end

function supports_style(::Type{F}, ::Style) where {F<:AbstractFormat}
    return false
end

function supports_style(::Type{F}, ::Nothing) where {F<:AbstractFormat}
    return true
end

function style_types()
    return Type[Nothing; subtypes(Style)]
end

function styles()
    return Union{Style,Nothing}[sty() for sty in style_types()]
end

@doc raw"""
    DWaveStyle <: Style

""" struct DWaveStyle <: Style end

Style(::Val{:dwave}) = DWaveStyle()

Base.show(io::IO, ::DWaveStyle) = print(io, "$(Style)(:dwave)")

@doc raw"""
    MQLibStyle <: Style

""" struct MQLibStyle <: Style end

Style(::Val{:mqlib}) = MQLibStyle()

Base.show(io::IO, ::MQLibStyle) = print(io, "$(Style)(:mqlib)")