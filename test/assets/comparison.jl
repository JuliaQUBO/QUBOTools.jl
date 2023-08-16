# Here, specialized methods for comparing models & solutions are provided.
# The idea is not to put a big burden into the Base operators (==, isapprox)
# and also to directly access the test interface.

function _compare_frames(src::QUBOTools.Frame, dst::QUBOTools.Frame)::Bool
    QUBOTools.sense(src) === QUBOTools.sense(dst) || return false
    QUBOTools.domain(src) === QUBOTools.domain(dst) || return false

    return true
end

function _compare_models(
    src::M,
    dst::M;
    # comparison settings
    compare_metadata::Bool = true,
    compare_solutions::Bool = false,
    compare_solution_metadata::Bool = compare_solutions,
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)::Bool where {V,T,U,M<:QUBOTools.AbstractModel{V,T,U}}
    _compare_frames(QUBOTools.frame(src), QUBOTools.frame(dst)) || return false

    _compare_variables(QUBOTools.variables(src), QUBOTools.variables(dst)) || return false

    _compare_forms(QUBOTools.form(src), QUBOTools.form(dst); atol) || return false

    if compare_metadata
        _compare_metadata(QUBOTools.metadata(src), QUBOTools.metadata(dst); atol) ||
            return false
    end

    if compare_solutions
        _compare_solutions(
            QUBOTools.solution(src),
            QUBOTools.solution(dst);
            compare_metadata = compare_solution_metadata,
            atol,
        ) || return false
    end

    return true
end

function _compare_variables(src::Vector{V}, dst::Vector{V})::Bool where {V}
    src == dst || return false

    return true
end

function _compare_forms(
    src::F,
    dst::F;
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)::Bool where {T,F<:QUBOTools.AbstractForm{T}}
    _compare_frames(QUBOTools.frame(src), QUBOTools.frame(dst)) || return false

    QUBOTools.dimension(src) == QUBOTools.dimension(dst) || return false
    isapprox(QUBOTools.scale(src), QUBOTools.scale(dst); atol) || return false
    isapprox(QUBOTools.offset(src), QUBOTools.offset(dst); atol) || return false

    src_lt = Dict{Int,T}(QUBOTools.linear_terms(src))
    dst_lt = Dict{Int,T}(QUBOTools.linear_terms(dst))

    for i in union(keys(src_lt), keys(dst_lt))
        isapprox(get(src_lt, i, zero(T)), get(dst_lt, i, zero(T)); atol) || return false
    end

    src_qt = Dict{Tuple{Int,Int},T}(QUBOTools.quadratic_terms(src))
    dst_qt = Dict{Tuple{Int,Int},T}(QUBOTools.quadratic_terms(dst))

    for (i, j) in union(keys(src_qt), keys(dst_qt))
        isapprox(get(src_qt, (i, j), zero(T)), get(dst_qt, (i, j), zero(T)); atol) ||
            return false
    end

    return true
end

function _compare_solutions(
    src::S,
    dst::S;
    # comparison settings
    compare_metadata::Bool = true,
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)::Bool where {T,U,S<:QUBOTools.AbstractSolution{T,U}}
    _compare_frames(QUBOTools.frame(src), QUBOTools.frame(dst)) || return false

    length(src) == length(dst) || return false

    for (x, y) in zip(src, dst)
        _compare_samples(x, y) || return false
    end

    if compare_metadata
        _compare_metadata(QUBOTools.metadata(src), QUBOTools.metadata(dst); atol) ||
            return false
    end

    return true
end

function _compare_samples(
    src::S,
    dst::S;
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)::Bool where {T,U,S<:QUBOTools.AbstractSample{T,U}}
    QUBOTools.reads(src) == QUBOTools.reads(dst) || return false
    QUBOTools.state(src) == QUBOTools.state(dst) || return false
    isapprox(QUBOTools.value(src), QUBOTools.value(dst); atol) || return false

    return true
end

function _compare_metadata(src::T, dst::U; kws...)::Bool where {T,U}
    return false # different types -> false
end

function _compare_metadata(src::T, dst::T; kws...)::Bool where {T}
    return src == dst # same type -> ==
end

function _compare_metadata(
    src::Float64,
    dst::Float64;
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)::Bool
    return isapprox(src, dst; atol)
end

function _compare_metadata(
    src::Dict{String,Any},
    dst::Dict{String,Any};
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)::Bool
    for key in union(keys(src), keys(dst))
        haskey(src, key) && haskey(dst, key) || return false

        src_val = src[key]
        dst_val = dst[key]

        _compare_metadata(src_val, dst_val; atol) || return false
    end

    return true
end
