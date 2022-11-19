struct CodecError <: Exception
    msg::Union{String,Nothing}

    function CodecError(msg::Union{String,Nothing}=nothing)
        new(msg)
    end
end

function Base.showerror(io::IO, e::CodecError)
    if isnothing(e.msg)
        print(io, "Codec Error")
    else
        print(io, "Codec Error: $(e.msg)")
    end
end

function codec_error(msg::Union{String,Nothing}=nothing)
    throw(CodecError(msg))
end

struct SampleError <: Exception
    msg::Union{String,Nothing}

    function SampleError(msg::Union{String,Nothing}=nothing)
        new(msg)
    end
end

function Base.showerror(io::IO, e::SampleError)
    if isnothing(e.msg)
        print(io, "Sample Error")
    else
        print(io, "Sample Error: $(e.msg)")
    end
end

function sample_error(msg::Union{String,Nothing}=nothing)
    throw(SampleError(msg))
end