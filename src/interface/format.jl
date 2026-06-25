@doc raw"""
    AbstractFormat

Supertype for QUBOTools file-format descriptors used by model and solution I/O.
"""
abstract type AbstractFormat end

@doc raw"""
    Format{F}

Concrete format descriptor for format `F`, storing validated format-specific
settings.
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
    FormatInferenceError

Thrown when QUBOTools cannot infer a supported format from a path or hint
sequence.
"""
struct FormatInferenceError{S} <: Exception
    source::S

    FormatInferenceError(source::Vector{Symbol})                = new{Vector{Symbol}}(source)
    FormatInferenceError(source::S) where {S <: AbstractString} = new{String}(String(source))
end

function Base.showerror(io::IO, err::FormatInferenceError{S}) where {S <: AbstractString}
    print(io, "FormatInferenceError: Unable to infer file format from path: '$(err.source)'")
end

function Base.showerror(io::IO, err::FormatInferenceError{Vector{Symbol}})
    print(io, "FormatInferenceError: Unable to infer file format from keys: '$(err.source)'")
end

function format_inference_error(source)
    throw(FormatInferenceError(source))
end

@doc raw"""
    infer_format(hints::Vector{Symbol})::Format
    infer_format(; path::AbstractString)

Infer a QUBOTools file format from ordered hint symbols or from the suffixes of
`path`.
"""
function infer_format end

infer_format(::Val)                = nothing
infer_format(::Val, hints::Val...) = infer_format(hints...)

function infer_format(hints::Vector{Symbol})::Format
    fmt = infer_format(Val.(hints)...)

    isnothing(fmt) && format_inference_error(hints)

    return fmt
end

function infer_format(; path::AbstractString)::Format
    hints = _format_hints(path)

    isempty(hints) && format_inference_error(path)

    fmt = infer_format(Val.(hints)...)

    isnothing(fmt) && format_inference_error(path)
    
    return fmt
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

    return reverse(hints)
end
