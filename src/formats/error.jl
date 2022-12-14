struct FormatError <: Exception
    msg::Union{String,Nothing}

    FormatError(msg::Union{String,Nothing}=nothing) = new(msg)
end

function Base.showerror(io::IO, e::FormatError)
    if isnothing(e.msg)
        print(io, "Format Error")
    else
        print(io, "Format Error: $(e.msg)")
    end
end

function format_error(msg::Union{String,Nothing} = nothing)
    throw(FormatError(msg))
end

struct SyntaxError <: Exception
    msg::Union{String,Nothing}

    SyntaxError(msg::Union{String,Nothing}=nothing) = new(msg)
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
end

function syntax_warning(msg::String)
    @warn "Syntax Warning: $msg"

    return nothing
end