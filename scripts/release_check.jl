#!/usr/bin/env julia

using Pkg
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))

function release_line_compat(version::VersionNumber)
    if version.major == 0
        return version.minor == 0 ? "0.0.$(version.patch)" : "0.$(version.minor)"
    end

    return string(version.major)
end

function check!(failures::Vector{String}, condition::Bool, message::String)
    condition || push!(failures, message)
    return nothing
end

function project_file(parts...)
    return joinpath(ROOT, parts...)
end

function read_toml(parts...)
    return TOML.parsefile(project_file(parts...))
end

function compat_entries(compat::AbstractString)
    return strip.(split(compat, ","))
end

function compat_allows(compat::AbstractString, version::VersionNumber)
    return version in Pkg.Types.semver_spec(compat)
end

function release_heading_matches(line::AbstractString, version::VersionNumber)
    prefix = "## v$(version)"
    startswith(line, prefix) || return false
    length(line) == length(prefix) && return true
    return line[length(prefix) + 1] in (' ', '-', '(')
end

function release_section(changelog::String, version::VersionNumber)
    lines = split(changelog, '\n')
    start = findfirst(line -> release_heading_matches(line, version), lines)
    start === nothing && return nothing

    next_heading = findnext(line -> startswith(line, "## "), lines, start + 1)
    stop = next_heading === nothing ? lastindex(lines) : next_heading - 1
    return join(lines[start:stop], "\n")
end

function check_self_compat!(
    failures::Vector{String},
    project::Dict{String,Any},
    env_project::Dict{String,Any},
    env_name::AbstractString,
    expected_self_compat::AbstractString,
    version::VersionNumber,
)
    env_deps = env_project["deps"]
    env_compat = env_project["compat"]
    env_self_compat = get(env_compat, "QUBOTools", nothing)

    check!(
        failures,
        get(env_deps, "QUBOTools", nothing) == project["uuid"],
        "$env_name/Project.toml must depend on this package UUID for QUBOTools.",
    )
    check!(
        failures,
        env_self_compat !== nothing,
        "$env_name/Project.toml must declare QUBOTools compat.",
    )

    if env_self_compat !== nothing
        check!(
            failures,
            expected_self_compat in compat_entries(env_self_compat),
            "$env_name/Project.toml compat for QUBOTools must include \"$expected_self_compat\" for version $version.",
        )
        check!(
            failures,
            compat_allows(env_self_compat, version),
            "$env_name/Project.toml compat for QUBOTools must allow version $version.",
        )
    end

    return nothing
end

function main()
    failures = String[]
    warnings = String[]

    project = read_toml("Project.toml")
    docs_project = read_toml("docs", "Project.toml")
    benchmark_project = read_toml("benchmark", "Project.toml")

    version = VersionNumber(project["version"])
    expected_self_compat = release_line_compat(version)

    check!(failures, project["name"] == "QUBOTools", "Project.toml name is not QUBOTools.")

    project_compat = project["compat"]

    check_self_compat!(
        failures,
        project,
        docs_project,
        "docs",
        expected_self_compat,
        version,
    )
    check_self_compat!(
        failures,
        project,
        benchmark_project,
        "benchmark",
        expected_self_compat,
        version,
    )

    check!(
        failures,
        haskey(project_compat, "julia"),
        "Project.toml must declare Julia compat.",
    )

    changelog = read(project_file("CHANGELOG.md"), String)
    section = release_section(changelog, version)
    check!(
        failures,
        section !== nothing,
        "CHANGELOG.md must contain a release heading for v$version.",
    )

    if section !== nothing &&
       version.major == 0 &&
       iszero(version.patch) &&
       !occursin(r"(?i)\b(breaking|changelog)\b", section)
        push!(
            warnings,
            "CHANGELOG.md section for v$version does not mention `breaking` or `changelog`; General AutoMerge may require one of those words if the registry labels the release BREAKING.",
        )
    end

    if isempty(failures)
        println("Release preflight passed for QUBOTools v$version.")
        println("Expected docs self-compat entry: QUBOTools = \"$expected_self_compat\".")
    else
        println(stderr, "Release preflight failed:")
        foreach(message -> println(stderr, "- ", message), failures)
    end

    if !isempty(warnings)
        println(stderr, "\nWarnings:")
        foreach(message -> println(stderr, "- ", message), warnings)
    end

    return isempty(failures) ? 0 : 1
end

exit(main())
