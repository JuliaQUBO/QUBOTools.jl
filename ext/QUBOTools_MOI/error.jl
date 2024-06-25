struct QUBOParsingError <: Exception
    msg::String
    ads::Bool

    function QUBOParsingError(msg::AbstractString; ads::Bool = true)
        return new(msg, ads)
    end
end

function qubo_parsing_error(msg::AbstractString; ads::Bool = true)
    throw(QUBOParsingError(msg; ads))
end

function Base.showerror(io::IO, e::QUBOParsingError)
    print(io, e.msg)

    if e.ads
        println(
            io,
            """
            The current model could not be directly converted to the QUBO format.
            Consider using the `ToQUBO.jl` package.
                pkg> add ToQUBO 
                using JuMP, ToQUBO, YourSolver
                model = Model(() -> ToQUBO.Optimizer(YourSolver.Optimizer))
            """,
        )
    end

    return nothing
end