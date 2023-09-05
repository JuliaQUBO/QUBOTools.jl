@doc raw"""
    SolutionError

Error occurred while gathering solutions.
"""
struct SolutionError <: Exception
    msg::Union{String,Nothing}

    function SolutionError(msg::Union{String,Nothing} = nothing)
        new(msg)
    end
end

function Base.showerror(io::IO, e::SolutionError)
    if isnothing(e.msg)
        print(io, "Solution Error")
    else
        print(io, "Solution Error: $(e.msg)")
    end
end

function solution_error(msg::Union{String,Nothing} = nothing)
    throw(SolutionError(msg))

    return nothing
end

@doc raw"""
    FormatError

Error related to the format specification.
"""
struct FormatError <: Exception
    fmt::Any
    msg::Union{String,Nothing}

    FormatError(fmt, msg::Union{String,Nothing} = nothing) = new(fmt, msg)
end

function Base.showerror(io::IO, e::FormatError)
    if isnothing(e.msg)
        print(io, "Format Error for '$(e.fmt)'")
    else
        print(io, "Format Error for '$(e.fmt)': $(e.msg)")
    end
end

function format_error(msg::Union{String,Nothing} = nothing)
    throw(FormatError(msg))

    return nothing
end

@doc raw"""
    SyntaxError

Syntax error while parsing file.
"""
struct SyntaxError <: Exception
    msg::Union{String,Nothing}

    SyntaxError(msg::Union{String,Nothing} = nothing) = new(msg)
end

function Base.showerror(io::IO, e::SyntaxError)
    if isnothing(e.msg)
        print(io, "Syntax Error")
    else
        print(io, "Syntax Error: $(e.msg)")
    end
end

function syntax_error(msg::Union{String,Nothing} = nothing)
    throw(SyntaxError(msg))

    return nothing
end

function syntax_warning(msg::AbstractString)
    @warn "Syntax Warning: $msg"

    return nothing
end

@doc raw"""
    CastingError

Error while casting data between domains or senses.
"""
struct CastingError <: Exception
    msg::Union{String,Nothing}

    CastingError(msg::Union{String,Nothing} = nothing) = new(msg)
end

function Base.showerror(io::IO, e::CastingError)
    if isnothing(e.msg)
        print(io, "Casting Error")
    else
        print(io, "Casting Error: $(e.msg)")
    end
end

function casting_error(msg::Union{String,Nothing} = nothing)
    throw(CastingError(msg))

    return nothing
end

function casting_error((s, t)::Route{X}, ::T) where {X,T}
    return casting_error("There is no known casting of '$T' from '$s' to '$t'")
end
