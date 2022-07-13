struct BQPCodecError <: Exception
    msg::Union{String, Nothing}

    function BQPCodecError(msg::Union{String, Nothing} = nothing)
        new(msg)
    end
end

function Base.showerror(io::IO, e::BQPCodecError)
    if isnothing(e.msg)
        print(io, "BQP Codec Error")
    else
        print(io, "BQP Codec Error: $(e.msg)")
    end
end

function bqpcodec_error(msg::Union{String, Nothing} = nothing)
    throw(BQPCodecError(msg))
end