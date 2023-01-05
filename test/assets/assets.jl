"""
    __data_path(::AbstractFormat, ::Val{dom}, ::Integer)
"""
function __data_path end

function __data_path(index::Integer, path::AbstractString)
    return joinpath(@__DIR__, "..", "data", @sprintf("%02d", index), path)
end

function __data_path(fmt::QUBOTools.AbstractFormat, dom::QUBOTools.Domain, i::Integer)
    return __data_path(fmt, dom, i)
end

__data_path(::QUBOTools.BQPJSON, ::Val{𝔹}, i::Integer)  = __data_path(i, "bool.json")
__data_path(::QUBOTools.BQPJSON, ::Val{𝕊}, i::Integer)  = __data_path(i, "spin.json")
__data_path(::QUBOTools.HFS, ::Val{𝔹}, i::Integer)      = __data_path(i, "bool.hfs")
__data_path(::QUBOTools.Qubist, ::Val{𝕊}, i::Integer)   = __data_path(i, "spin.qh")
__data_path(::QUBOTools.QUBO, ::Val{𝔹}, i::Integer)     = __data_path(i, "bool.qubo")
__data_path(::QUBOTools.MiniZinc, ::Val{𝔹}, i::Integer) = __data_path(i, "bool.mzn")
__data_path(::QUBOTools.MiniZinc, ::Val{𝕊}, i::Integer) = __data_path(i, "spin.mzn")
