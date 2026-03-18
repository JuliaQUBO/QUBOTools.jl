import Pkg

Pkg.instantiate()

using BenchmarkTools

const TIME_TOLERANCE = 0.15

function get_results(data_path)
    main_results_path = joinpath(data_path, "results-main.json")
    dev_results_path = joinpath(data_path, "results-dev.json")

    main_results = first(BenchmarkTools.load(main_results_path))
    dev_results = first(BenchmarkTools.load(dev_results_path))

    return get_results(main_results, dev_results)
end

function get_results(main_results, dev_results)
    results = Dict{String,Any}()

    for (key, value) in dev_results
        if value isa BenchmarkTools.BenchmarkGroup
            results[key] = get_results(main_results[key], value)
        elseif value isa BenchmarkTools.Trial
            results[key] = (main_results[key], value)
        end
    end

    return results
end

function status_label(status::Symbol)
    if status == :regression
        return "regression"
    elseif status == :improvement
        return "improvement"
    elseif status == :invariant
        return "invariant"
    else
        return "unknown"
    end
end

function diff_label(judgment)
    delta = BenchmarkTools.time(BenchmarkTools.ratio(judgment)) - 1

    return BenchmarkTools.prettypercent(delta)
end

function compare_results(results; keypath = "")
    report = String[]

    for (key, value) in results
        if value isa Dict
            append!(report, compare_results(value; keypath = "$keypath/$key"))
        elseif value isa Tuple
            main_trial, dev_trial = value
            case_id = "$keypath/$key"

            main_min = BenchmarkTools.minimum(main_trial)
            main_median = BenchmarkTools.median(main_trial)
            main_std = BenchmarkTools.std(main_trial)

            dev_min = BenchmarkTools.minimum(dev_trial)
            dev_median = BenchmarkTools.median(dev_trial)
            dev_std = BenchmarkTools.std(dev_trial)

            judgment = BenchmarkTools.judge(dev_min, main_min; time_tolerance = TIME_TOLERANCE)
            diff = diff_label(judgment)

            push!(
                report,
                "| `$case_id` | $(BenchmarkTools.prettytime(BenchmarkTools.time(main_min))) ($(BenchmarkTools.prettytime(BenchmarkTools.time(main_median)))) ± $(BenchmarkTools.prettytime(BenchmarkTools.time(main_std))) | $(BenchmarkTools.prettytime(BenchmarkTools.time(dev_min))) ($(BenchmarkTools.prettytime(BenchmarkTools.time(dev_median)))) ± $(BenchmarkTools.prettytime(BenchmarkTools.time(dev_std))) | $(status_label(BenchmarkTools.time(judgment))) ($(diff)) |",
            )
        end
    end

    return sort!(report)
end

function write_report(report, data_path)
    report_path = joinpath(data_path, "REPORT.md")

    open(report_path, "w") do io
        println(io, "# Performance Report - `main` vs. `dev`")
        println(io)
        println(io, "Timings are reported as `minimum (median) ± std`, and comparison uses a $(BenchmarkTools.prettypercent(TIME_TOLERANCE)) tolerance to reduce false positives on shared runners.")
        println(io)
        println(io, "| case | `main` | `dev` | diff |")
        println(io, "| :--- | :----: | :---: | :--: |")

        for entry in report
            println(io, entry)
        end
    end

    return report_path
end

function main()
    data_path = joinpath(@__DIR__, "data")

    results = get_results(data_path)
    report = compare_results(results)

    write_report(report, data_path)

    return nothing
end

if "--run" in ARGS
    main()
end
