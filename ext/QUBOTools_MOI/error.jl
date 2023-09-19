struct QUBOParsingError <: Exception
    msg::String
    ads::Bool

    function QUBOParsingError(msg::AbstractString; ads::Bool = true)
        return new(msg, ads)
    end
end

function qubo_parsing_error(msg::AbstractString; ads::Bool = true)
    throw(QUBOParsingError(msg; ads))

    return nothing
end

function Base.showerror(io::IO, e::QUBOParsingError)
    show(io, e.msg)

    if e.ads
        show(
            io,
            """
            It seems that the current model could not be converted to QUBO in a straightforward fashion 🙁
            Consider using the `ToQUBO.jl` package, a sophisticated reformulation framework.
                pkg> add ToQUBO # 😎
            """,
        )
    end

    return nothing
end