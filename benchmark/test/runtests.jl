import Pkg

Pkg.develop(; path = normpath(joinpath(@__DIR__, "..", "..")))
Pkg.instantiate()

using Test
using Random
using SparseArrays
using BenchmarkTools
using QUBOTools

include("../suites/fixtures.jl")
include("../suites/constructors.jl")
include("../suites/conversions.jl")
include("../suites/evaluation.jl")

@testset "Benchmark Fixtures" begin
    @test benchmark_seed("n=128", 128; quadratic_density = 0.08) == 0xe5c9c566

    fixture_a = benchmark_fixture("n=128", 128; quadratic_density = 0.08)
    fixture_b = benchmark_fixture("n=128", 128; quadratic_density = 0.08)

    @test fixture_a.linear == fixture_b.linear
    @test fixture_a.quadratic == fixture_b.quadratic
    @test fixture_a.psi == fixture_b.psi
end

@testset "Benchmark Suites" begin
    fixtures = benchmark_fixtures()

    suite = BenchmarkGroup()
    suite["constructors"] = BenchmarkGroup()
    suite["conversions"] = BenchmarkGroup()
    suite["evaluation"] = BenchmarkGroup()

    benchmark_constructors!(suite["constructors"], fixtures)
    benchmark_conversions!(suite["conversions"], fixtures)
    benchmark_evaluation!(suite["evaluation"], fixtures)

    for fixture in fixtures
        conversion_group = suite["conversions"][fixture.label]

        @test haskey(conversion_group, "ising/Matrix")
        @test haskey(conversion_group, "qubo/Matrix")
    end
end
