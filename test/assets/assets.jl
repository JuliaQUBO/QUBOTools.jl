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

__data_path(::QUBOTools.BQPJSON, ::QUBOTools.BoolDomain, i::Integer)  = __data_path(i, "bool.json")
__data_path(::QUBOTools.BQPJSON, ::QUBOTools.SpinDomain, i::Integer)  = __data_path(i, "spin.json")
__data_path(::QUBOTools.HFS, ::QUBOTools.BoolDomain, i::Integer)      = __data_path(i, "bool.hfs")
__data_path(::QUBOTools.Qubist, ::QUBOTools.SpinDomain, i::Integer)   = __data_path(i, "spin.qh")
__data_path(::QUBOTools.QUBO, ::QUBOTools.BoolDomain, i::Integer)     = __data_path(i, "bool.qubo")
__data_path(::QUBOTools.MiniZinc, ::QUBOTools.BoolDomain, i::Integer) = __data_path(i, "bool.mzn")
__data_path(::QUBOTools.MiniZinc, ::QUBOTools.SpinDomain, i::Integer) = __data_path(i, "spin.mzn")

"""
    __temp_path(::AbstractFormat, ::Val{dom}, ::Integer)
"""
function __temp_path end

function __temp_path(index::Integer, path::AbstractString)
    file_path = joinpath(tempname(; cleanup = true), @sprintf("%02d", index), path)

    mkpath(dirname(file_path))

    return file_path
end

__temp_path(::QUBOTools.BQPJSON, ::QUBOTools.BoolDomain, i::Integer)  = __temp_path(i, "bool.json")
__temp_path(::QUBOTools.BQPJSON, ::QUBOTools.SpinDomain, i::Integer)  = __temp_path(i, "spin.json")
__temp_path(::QUBOTools.HFS, ::QUBOTools.BoolDomain, i::Integer)      = __temp_path(i, "bool.hfs")
__temp_path(::QUBOTools.Qubist, ::QUBOTools.SpinDomain, i::Integer)   = __temp_path(i, "spin.qh")
__temp_path(::QUBOTools.QUBO, ::QUBOTools.BoolDomain, i::Integer)     = __temp_path(i, "bool.qubo")
__temp_path(::QUBOTools.MiniZinc, ::QUBOTools.BoolDomain, i::Integer) = __temp_path(i, "bool.mzn")
__temp_path(::QUBOTools.MiniZinc, ::QUBOTools.SpinDomain, i::Integer) = __temp_path(i, "spin.mzn")