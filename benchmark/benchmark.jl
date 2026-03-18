import Pkg
import Tar

function repository_root()
    return normpath(joinpath(@__DIR__, ".."))
end

function develop_origin_main!()
    repo_root = repository_root()

    success(`git -C $(repo_root) rev-parse --verify origin/main`) ||
        error("Missing local origin/main ref. Run `git fetch origin main` before benchmarking.")

    archive_path = tempname() * ".tar"
    checkout_path = mktempdir()
    atexit(() -> isdir(checkout_path) && rm(checkout_path; recursive = true, force = true))

    try
        run(`git -C $(repo_root) archive --output=$(archive_path) origin/main`)
        Tar.extract(archive_path, checkout_path)
    finally
        isfile(archive_path) && rm(archive_path; force = true)
    end

    Pkg.develop(; path = checkout_path)

    return nothing
end

function configure_environment()
    has_main = "--main" in ARGS
    has_dev = "--dev" in ARGS

    has_main && has_dev && error("Pass either --main or --dev, not both")

    if has_main
        develop_origin_main!()
    elseif has_dev
        Pkg.develop(; path = joinpath(@__DIR__, ".."))
    end

    Pkg.instantiate()

    return (; has_main, has_dev)
end

const RUN_CONFIG = configure_environment()

using Random
using SparseArrays
using BenchmarkTools
using QUBOTools

Random.seed!(0)

include("suites/fixtures.jl")
include("suites/constructors.jl")
include("suites/conversions.jl")
include("suites/evaluation.jl")

const SUITE = BenchmarkGroup()

function build_suite!()
    fixtures = benchmark_fixtures()

    SUITE["constructors"] = BenchmarkGroup()
    benchmark_constructors!(SUITE["constructors"], fixtures)

    SUITE["conversions"] = BenchmarkGroup()
    benchmark_conversions!(SUITE["conversions"], fixtures)

    SUITE["evaluation"] = BenchmarkGroup()
    benchmark_evaluation!(SUITE["evaluation"], fixtures)

    return SUITE
end

function benchmark_data_path()
    data_path = joinpath(@__DIR__, "data")

    mkpath(data_path)

    return data_path
end

function benchmark_main!(suite)
    data_path = benchmark_data_path()
    params_path = joinpath(data_path, "params.json")
    results_path = joinpath(data_path, "results-main.json")

    @info "Generating benchmark parameters against main"
    BenchmarkTools.tune!(suite)
    BenchmarkTools.save(params_path, params(suite))

    @info "Running benchmark suite against main"
    results = BenchmarkTools.run(suite)

    BenchmarkTools.save(results_path, results)

    return nothing
end

function benchmark_dev!(suite)
    data_path = benchmark_data_path()
    params_path = joinpath(data_path, "params.json")
    results_path = joinpath(data_path, "results-dev.json")

    isfile(params_path) || error("Missing benchmark parameters at $(params_path). Run --main first.")

    @info "Loading benchmark parameters for dev"
    loadparams!(suite, first(BenchmarkTools.load(params_path)), :evals, :samples)

    @info "Running benchmark suite against dev"
    results = BenchmarkTools.run(suite)

    BenchmarkTools.save(results_path, results)

    return nothing
end

function main()
    build_suite!()

    if "--run" in ARGS
        if RUN_CONFIG.has_main
            benchmark_main!(SUITE)
        elseif RUN_CONFIG.has_dev
            benchmark_dev!(SUITE)
        else
            error("Pass --main or --dev together with --run")
        end
    end

    return nothing
end

main()
