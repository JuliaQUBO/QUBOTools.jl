@doc raw"""
    AbstractFormat

"""
abstract type AbstractFormat end

@doc raw"""
    Format{F}
"""
struct Format{F} <: AbstractFormat
    settings::Dict{Symbol,Any}

    function Format{F}(settings::Dict{Symbol,Any}) where {F}
        @assert F isa Symbol

        return new{F}(settings)
    end
end

Format{F}(; kws...) where {F} = error("Unknown format '$F'")

function Base.getindex(fmt::Format{F}, index...) where {F}
    return getindex(fmt.settings, index...)
end

@doc raw"""
    format(::AbstractString)::AbstractFormat
    format(::Symbol)::AbstractFormat
    format(::Symbol, ::Symbol)::AbstractFormat

Given the file path, tries to infer the type associated to a QUBO model format.
"""
function format end

@doc raw"""
    infer_format(; path::AbstractString)
"""
function infer_format end

infer_format(::Val)                = nothing
infer_format(::Val, hints::Val...) = infer_format(hints...)

function infer_format(; path::AbstractString)
    fmt = infer_format(_format_hints(path)...)

    if isnothing(fmt)
        error("`QUBOTools` was unable to infer the format from file path '$path'")
    else
        @assert fmt isa Format

        return fmt
    end
end

function _format_hints(subpath::AbstractString)
    hints = Symbol[]

    while true
        subpath, pathext = splitext(subpath)
        pathext          = lstrip(pathext, '.')

        if isempty(pathext)
            break
        else
            push!(hints, Symbol(pathext))
        end
    end

    return Val.(Iterators.reverse(hints))
end