import Pkg

Pkg.develop(; path = normpath(joinpath(@__DIR__, "..", "..")))
Pkg.instantiate()

using Test
using Random
using SparseArrays
using BenchmarkTools
using MathOptInterface
using QUBOTools

include("../suites/fixtures.jl")
include("../suites/constructors.jl")
include("../suites/conversions.jl")
include("../suites/evaluation.jl")

@testset "Benchmark Fixtures" begin
    @test benchmark_seed("n=128", 128; quadratic_density = 0.08) == 0xe5c9c566

    fixture_a = benchmark_fixture("n=128", 128; quadratic_density = 0.08)
    fixture_b = benchmark_fixture("n=128", 128; quadratic_density = 0.08)
    constructor_fixture = benchmark_constructor_fixture("n=128", 128; quadratic_density = 0.08)
    dict_model = QUBOTools.Model(
        constructor_fixture.linear,
        constructor_fixture.quadratic;
        offset = -1.0,
        sense = :min,
        domain = :bool,
    )
    moi_model = QUBOTools.Model(constructor_fixture.moi_model)

    @test fixture_a.linear == fixture_b.linear
    @test fixture_a.quadratic == fixture_b.quadratic
    @test fixture_a.psi == fixture_b.psi
    @test QUBOTools.dimension(moi_model) == 128
    @test Dict(QUBOTools.linear_terms(moi_model)) == Dict(QUBOTools.linear_terms(dict_model))
    @test Dict(QUBOTools.quadratic_terms(moi_model)) == Dict(QUBOTools.quadratic_terms(dict_model))
    @test QUBOTools.offset(moi_model) == QUBOTools.offset(dict_model)
    @test QUBOTools.sense(moi_model) === QUBOTools.Min
    @test QUBOTools.domain(moi_model) === QUBOTools.BoolDomain
end

@testset "Benchmark Suites" begin
    fixtures = benchmark_fixtures()
    constructor_fixtures = benchmark_constructor_fixtures()

    suite = BenchmarkGroup()
    suite["constructors"] = BenchmarkGroup()
    suite["conversions"] = BenchmarkGroup()
    suite["evaluation"] = BenchmarkGroup()

    benchmark_constructors!(suite["constructors"], constructor_fixtures)
    benchmark_conversions!(suite["conversions"], fixtures)
    benchmark_evaluation!(suite["evaluation"], fixtures)

    @test haskey(suite["constructors"], "n=2048")
    @test haskey(suite["constructors"]["n=2048"], "Model/MOI")

    for fixture in fixtures
        conversion_group = suite["conversions"][fixture.label]

        @test haskey(conversion_group, "ising/Matrix")
        @test haskey(conversion_group, "qubo/Matrix")
    end
end
