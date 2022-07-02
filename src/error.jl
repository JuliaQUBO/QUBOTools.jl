struct SyntaxError <: Exception
    msg::Union{String, Nothing}

    function SyntaxError(msg::Union{String, Nothing} = nothing)
        new(msg)
    end
end

function Base.showerror(io::IO, e::SyntaxError)
    if isnothing(e.msg)
        print(io, "Syntax Error")
    else
        print(io, "Syntax Error: $(e.msg)")
    end
end