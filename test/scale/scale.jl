const _SCALE_TRUE_VALUES = Set(["1", "true", "yes", "on"])

struct _ScaleCase
    n::Int
    avg_degree::Int
    construction_seconds::Float64
    construction_mib::Float64
    evaluation_seconds::Float64
    evaluation_mib::Float64
    qubin_seconds::Float64
    qubin_mib::Float64
    qubo_seconds::Float64
    qubo_mib::Float64
end

function _scale_tests_enabled()
    return lowercase(get(ENV, "QUBOTOOLS_SCALE_TESTS", "false")) in _SCALE_TRUE_VALUES
end

function _scale_env_int(name::AbstractString, default::Int)
    value = get(ENV, name, string(default))

    parsed = tryparse(Int, value)
    isnothing(parsed) && error("$(name) must be an integer, got '$(value)'")

    return parsed
end

function _scale_cases()
    max_n = _scale_env_int("QUBOTOOLS_SCALE_MAX_N", 100_000)
    cases = _ScaleCase[
        _ScaleCase(1_000, 4, 10.0, 512.0, 2.0, 128.0, 20.0, 768.0, 20.0, 768.0),
        _ScaleCase(5_000, 4, 10.0, 512.0, 2.0, 128.0, 20.0, 768.0, 20.0, 768.0),
        _ScaleCase(20_000, 4, 20.0, 768.0, 5.0, 256.0, 60.0, 1_024.0, 60.0, 1_024.0),
        _ScaleCase(100_000, 4, 60.0, 1_536.0, 10.0, 512.0, 180.0, 2_048.0, 180.0, 2_048.0),
    ]

    return filter(case -> case.n <= max_n, cases)
end

function _scale_sparse_er_model(n::Int; avg_degree::Int, seed::Int)
    rng = Random.MersenneTwister(seed)
    variables = Set{Int}(1:n)
    linear_terms = sizehint!(Dict{Int,Float64}(), n)

    for i in 1:n
        linear_terms[i] = randn(rng)
    end

    target_edges = max(1, (n * avg_degree) ÷ 2)
    quadratic_terms = sizehint!(Dict{Tuple{Int,Int},Float64}(), target_edges)

    while length(quadratic_terms) < target_edges
        i = rand(rng, 1:(n - 1))
        j = rand(rng, (i + 1):n)

        quadratic_terms[(i, j)] = randn(rng)
    end

    return QUBOTools.Model{Int,Float64,Int}(
        variables,
        linear_terms,
        quadratic_terms;
        sense = :min,
        domain = :bool,
        metadata = Dict{String,Any}(
            "scale_test" => true,
            "generator" => "sparse_er",
            "avg_degree" => avg_degree,
        ),
    )
end

function _scale_portfolio_like_model()
    magnitudes = [
        1.0e-3,
        -2.5e-2,
        3.75e-1,
        -4.5,
        6.25e3,
        -8.0e6,
        1.25e9,
        -2.0e10,
    ]
    linear_terms = Dict{Int,Float64}(i => magnitudes[i] for i in eachindex(magnitudes))
    quadratic_terms = Dict{Tuple{Int,Int},Float64}(
        (1, 8) => 2.0e10,
        (2, 7) => -1.0e-3,
        (3, 6) => 5.125e5,
        (4, 5) => -7.25e8,
    )

    return QUBOTools.Model{Int,Float64,Int}(
        Set{Int}(1:length(magnitudes)),
        linear_terms,
        quadratic_terms;
        offset = 1.0e-3,
        sense = :min,
        domain = :bool,
        metadata = Dict{String,Any}("scale_test" => "numerical_range"),
    )
end

function _scale_timed(f::Function, label::AbstractString, seconds::Real, mib::Real)
    result = @timed f()

    @info label time = result.time mib = result.bytes / 2.0^20
    @test result.time <= seconds
    @test result.bytes <= mib * 2.0^20

    return result.value
end

function _scale_with_temp_path(f::Function, suffix::AbstractString)
    path = "$(tempname()).$(suffix)"

    try
        return f(path)
    finally
        rm(path; force = true)
    end
end

function _scale_roundtrip(model, suffix::AbstractString)
    return _scale_with_temp_path(suffix) do path
        QUBOTools.write_model(path, model)

        return QUBOTools.read_model(path)
    end
end

function _scale_linear_terms(model)
    return Dict{Int,Float64}(QUBOTools.linear_terms(model))
end

function _scale_quadratic_terms(model)
    return Dict{Tuple{Int,Int},Float64}(QUBOTools.quadratic_terms(model))
end

function _scale_assert_same_terms(src::AbstractDict{K,T}, dst::AbstractDict{K,T}) where {K,T}
    @test keys(src) == keys(dst)

    for key in keys(src)
        @test dst[key] ≈ src[key]
    end

    return nothing
end

function _scale_assert_same_model(src, dst; exact::Bool = false)
    @test QUBOTools.dimension(dst) == QUBOTools.dimension(src)
    @test QUBOTools.variables(dst) == QUBOTools.variables(src)
    @test QUBOTools.metadata(dst) == QUBOTools.metadata(src)
    @test QUBOTools.sense(dst) === QUBOTools.sense(src)
    @test QUBOTools.domain(dst) === QUBOTools.domain(src)

    if exact
        @test QUBOTools.scale(dst) == QUBOTools.scale(src)
        @test QUBOTools.offset(dst) == QUBOTools.offset(src)
        @test _scale_linear_terms(dst) == _scale_linear_terms(src)
        @test _scale_quadratic_terms(dst) == _scale_quadratic_terms(src)
    else
        @test QUBOTools.scale(dst) ≈ QUBOTools.scale(src)
        @test QUBOTools.offset(dst) ≈ QUBOTools.offset(src)
        _scale_assert_same_terms(_scale_linear_terms(src), _scale_linear_terms(dst))
        _scale_assert_same_terms(_scale_quadratic_terms(src), _scale_quadratic_terms(dst))
    end

    return nothing
end

function _scale_random_states(n::Int, count::Int; seed::Int)
    rng = Random.MersenneTwister(seed)

    return [rand(rng, 0:1, n) for _ in 1:count]
end

function _scale_assert_value_preserved(src, dst, states)
    for state in states
        @test QUBOTools.value(dst, state) ≈ QUBOTools.value(src, state)
    end

    return nothing
end

function _scale_warmup()
    model = _scale_sparse_er_model(32; avg_degree = 4, seed = 41)
    state = first(_scale_random_states(32, 1; seed = 42))

    QUBOTools.value(model, state)
    QUBOTools.form(model, :dict)
    QUBOTools.form(model, :dense)
    _scale_roundtrip(model, "qb")
    _scale_roundtrip(model, "qubo")

    return nothing
end

function _scale_test_form_correctness(model, states; include_dense::Bool)
    sparse_form = QUBOTools.form(model)
    dict_form = QUBOTools.form(model, :dict)

    for state in states
        @test QUBOTools.value(state, dict_form) ≈ QUBOTools.value(state, sparse_form)
    end

    if include_dense
        dense_form = QUBOTools.form(model, :dense)

        for state in states
            @test QUBOTools.value(state, dense_form) ≈ QUBOTools.value(state, sparse_form)
        end
    end

    return nothing
end

function _scale_test_sampleset(model, states)
    repeated = [first(states), copy(first(states))]
    samples = QUBOTools.SampleSet{Float64,Int}(model, repeated)

    @test length(samples) == 1
    @test QUBOTools.dimension(samples) == QUBOTools.dimension(model)
    @test QUBOTools.reads(first(samples)) == 2

    return nothing
end

function _scale_test_synthesis_generators()
    @testset "synthesis generators" begin
        generators = [
            ("Sherrington-Kirkpatrick", QUBOTools.SherringtonKirkpatrick(1_000), 10.0, 1_024.0),
            ("Wishart", QUBOTools.Wishart(1_000, 4), 10.0, 1_536.0),
        ]

        for (label, problem, seconds, mib) in generators
            model = _scale_timed(label, seconds, mib) do
                @test_logs (:warn, r"Depraction Warning") QUBOTools.generate(
                    Random.MersenneTwister(3000),
                    problem,
                )
            end

            @test QUBOTools.dimension(model) == 1_000
            @test QUBOTools.quadratic_size(model) == 499_500

            states = _scale_random_states(1_000, 2; seed = 3100)
            _scale_test_form_correctness(model, states; include_dense = false)
        end
    end

    return nothing
end

function _scale_test_case(case::_ScaleCase)
    @testset "n=$(case.n), avg_degree=$(case.avg_degree)" begin
        model = _scale_timed(
            "construct n=$(case.n)",
            case.construction_seconds,
            case.construction_mib,
        ) do
            _scale_sparse_er_model(case.n; avg_degree = case.avg_degree, seed = 1000 + case.n)
        end

        @test QUBOTools.dimension(model) == case.n
        @test QUBOTools.quadratic_size(model) == (case.n * case.avg_degree) ÷ 2

        states = _scale_random_states(case.n, 3; seed = 2000 + case.n)

        _scale_timed("evaluate n=$(case.n)", case.evaluation_seconds, case.evaluation_mib) do
            for state in states
                QUBOTools.value(model, state)
            end
        end

        _scale_test_form_correctness(model, states; include_dense = case.n <= 1_000)
        _scale_test_sampleset(model, states)

        qubin_model = _scale_timed(
            "QUBin round-trip n=$(case.n)",
            case.qubin_seconds,
            case.qubin_mib,
        ) do
            _scale_roundtrip(model, "qb")
        end
        _scale_assert_same_model(model, qubin_model; exact = true)
        _scale_assert_value_preserved(model, qubin_model, states)

        if case.n >= 20_000
            qubo_model = _scale_timed(
                "QUBO round-trip n=$(case.n)",
                case.qubo_seconds,
                case.qubo_mib,
            ) do
                _scale_roundtrip(model, "qubo")
            end
            _scale_assert_same_model(model, qubo_model; exact = true)
            _scale_assert_value_preserved(model, qubo_model, states)
        end
    end

    return nothing
end

function _scale_test_numerical_range()
    @testset "numerical range" begin
        model = _scale_portfolio_like_model()
        states = _scale_random_states(QUBOTools.dimension(model), 4; seed = 90)

        for suffix in ("qb", "qubo")
            dst = _scale_roundtrip(model, suffix)

            _scale_assert_same_model(model, dst; exact = true)
            _scale_assert_value_preserved(model, dst, states)
        end
    end

    return nothing
end

function test_scale()
    cases = _scale_cases()

    @testset "△ Scale Tests" verbose = true begin
        @test !isempty(cases)

        _scale_warmup()
        _scale_test_synthesis_generators()

        for case in cases
            _scale_test_case(case)
        end

        _scale_test_numerical_range()
    end

    return nothing
end
