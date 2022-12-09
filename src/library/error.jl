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

struct SamplingError <: Exception
    msg::Union{String,Nothing}

    function SamplingError(msg::Union{String,Nothing}=nothing)
        new(msg)
    end
end

function Base.showerror(io::IO, e::SamplingError)
    if isnothing(e.msg)
        print(io, "Sampling Error")
    else
        print(io, "Sampling Error: $(e.msg)")
    end
end

function sampling_error(msg::Union{String,Nothing}=nothing)
    throw(SamplingError(msg))
end