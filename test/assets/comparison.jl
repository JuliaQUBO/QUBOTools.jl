# Here, specialized methods for comparing models & solutions are provided.
# The idea is not to put a big burden into the Base operators (==, isapprox)
# and also to directly access the test interface.

function _compare_frames(src::QUBOTools.Frame, dst::QUBOTools.Frame)
    @test QUBOTools.sense(src) === QUBOTools.sense(dst)
    @test QUBOTools.domain(src) === QUBOTools.domain(dst)

    return nothing
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
) where {V,T,U,M<:QUBOTools.AbstractModel{V,T,U}}
    _compare_frames(QUBOTools.frame(src), QUBOTools.frame(dst))

    _compare_variables(QUBOTools.variables(src), QUBOTools.variables(dst))

    _compare_forms(
        QUBOTools.form(src),
        QUBOTools.form(dst);
        atol
    )

    if compare_metadata
        _compare_metadata(
            QUBOTools.metadata(src),
            QUBOTools.metadata(dst);
            atol
        )
    end

    if compare_solutions
        _compare_solutions(
            QUBOTools.solution(src),
            QUBOTools.solution(dst);
            compare_metadata = compare_solution_metadata,
            atol,
        )
    end

    return nothing
end

@inline function _compare_variables(src::Vector{V}, dst::Vector{V}) where {V}
    @test src == dst

    return nothing
end

function _compare_forms(
    src::F,
    dst::F;
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
) where {T,F<:QUBOTools.AbstractForm{T}}
    _compare_frames(QUBOTools.frame(src), QUBOTools.frame(dst))

    @test QUBOTools.dimension(src) == QUBOTools.dimension(dst)
    @test isapprox(QUBOTools.scale(src), QUBOTools.scale(dst); atol)
    @test isapprox(QUBOTools.offset(src), QUBOTools.offset(dst); atol)

    src_lt = Dict{Int,T}(QUBOTools.linear_terms(src))
    dst_lt = Dict{Int,T}(QUBOTools.linear_terms(dst))

    for i in union(keys(src_lt), keys(dst_lt))
        @test isapprox(get(src_lt, i, zero(T)), get(dst_lt, i, zero(T)); atol)
    end

    src_qt = Dict{Tuple{Int,Int},T}(QUBOTools.quadratic_terms(src))
    dst_qt = Dict{Tuple{Int,Int},T}(QUBOTools.quadratic_terms(dst))

    for (i, j) in union(keys(src_qt), keys(dst_qt))
        @test isapprox(get(src_qt, (i, j), zero(T)), get(dst_qt, (i, j), zero(T)); atol)
    end

    return nothing
end

function _compare_solutions(
    src::S,
    dst::S;
    # comparison settings
    compare_metadata::Bool = true,
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
) where {T,U,S<:QUBOTools.AbstractSolution{T,U}}
    _compare_frames(QUBOTools.frame(src), QUBOTools.frame(dst))

    @test length(src) == length(dst)

    for (x, y) in zip(src, dst)
        _compare_samples(x, y)
    end

    if compare_metadata
        _compare_metadata(QUBOTools.metadata(src), QUBOTools.metadata(dst); atol)
    end

    return nothing
end

function _compare_samples(
    src::S,
    dst::S;
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
) where {T,U,S<:QUBOTools.AbstractSample{T,U}}
    @test QUBOTools.reads(src) == QUBOTools.reads(dst)
    @test QUBOTools.state(src) == QUBOTools.state(dst)
    @test isapprox(QUBOTools.value(src), QUBOTools.value(dst); atol)

    return nothing
end

function _compare_metadata(
    src::Dict{String,Any},
    dst::Dict{String,Any};
    # absolute approximation tolerance
    atol::Float64 = 1E-6,
)
    for key in union(keys(src), keys(dst))
        @test haskey(src, key) && haskey(dst, key)

        src_val = src[key]
        dst_val = src[key]

        @test typeof(src_val) === typeof(dst_val)

        if src_val isa Dict{String,Any}
            _compare_metadata(src_val, dst_val; atol)
        elseif src_val isa Float64
            @test isapprox(src_val, dst_val; atol)
        else
            @test src_val == dst_val
        end
    end

    return nothing
end
