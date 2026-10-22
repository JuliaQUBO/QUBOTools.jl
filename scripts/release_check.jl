#!/usr/bin/env julia

module ReleaseCheck

using Pkg
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const CONCEPT_DOI = "10.5281/zenodo.7076341"
const ARTICLE_DOI = "10.1080/10556788.2026.2702926"
const OBSOLETE_VERSION_DOIS = ("10.5281/zenodo.13879606", "10.5281/zenodo.19463565")

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

function project_file(root::AbstractString, parts...)
    return joinpath(root, parts...)
end

function read_toml(root::AbstractString, parts...)
    return TOML.parsefile(project_file(root, parts...))
end

function read_text(root::AbstractString, parts...)
    return replace(read(project_file(root, parts...), String), "\r\n" => "\n")
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

function release_section(changelog::AbstractString, version::VersionNumber)
    lines = split(changelog, '\n')
    start = findfirst(line -> release_heading_matches(line, version), lines)
    start === nothing && return nothing

    next_heading = findnext(line -> startswith(line, "## "), lines, start + 1)
    stop = next_heading === nothing ? lastindex(lines) : next_heading - 1
    return join(lines[start:stop], "\n")
end

function release_date(changelog::AbstractString, version::VersionNumber)
    lines = split(changelog, '\n')
    idx = findfirst(line -> release_heading_matches(line, version), lines)
    idx === nothing && return nothing

    result = match(r"\b(\d{4}-\d{2}-\d{2})\b", lines[idx])
    return result === nothing ? nothing : only(result.captures)
end

function marked_section(
    document::AbstractString,
    start_marker::AbstractString,
    end_marker::AbstractString,
)
    start_parts = split(document, start_marker; limit = 2)
    length(start_parts) == 2 || return nothing

    end_parts = split(start_parts[2], end_marker; limit = 2)
    length(end_parts) == 2 || return nothing

    return strip(end_parts[1])
end

function quoted_cff_value(citation::AbstractString, key::AbstractString)
    result = match(Regex("(?m)^$(key):\\s*\"([^\"]+)\"\\s*\$"), citation)
    return result === nothing ? nothing : only(result.captures)
end

function cff_version_identifier(citation::AbstractString)
    result = match(
        r"(?ms)value:\s*\"(10\.5281/zenodo\.\d+)\"\s*\n\s*description:\s*\"Zenodo DOI for version\s+([0-9]+\.[0-9]+\.[0-9]+)\"",
        citation,
    )
    result === nothing && return (doi = nothing, version = nothing)
    return (doi = result.captures[1], version = result.captures[2])
end

function preferred_citation_block(citation::AbstractString)
    parts = split(citation, "preferred-citation:"; limit = 2)
    return length(parts) == 2 ? parts[2] : nothing
end

function preferred_citation_title(citation::AbstractString)
    block = preferred_citation_block(citation)
    block === nothing && return nothing

    result = match(r"(?m)^\s+title:\s*\"([^\"]+)\"\s*$", block)
    return result === nothing ? nothing : only(result.captures)
end

function preferred_citation_doi(citation::AbstractString)
    block = preferred_citation_block(citation)
    block === nothing && return nothing

    result = match(r"(?m)^\s+doi:\s*\"([^\"]+)\"\s*$", block)
    return result === nothing ? nothing : only(result.captures)
end

function bibtex_entry(bib::AbstractString, entry_type::AbstractString)
    result = match(Regex("(?ms)^@$(entry_type)\\{.*?^\\}"), bib)
    return result === nothing ? nothing : result.match
end

function bibtex_field(entry::AbstractString, field::AbstractString)
    result = match(Regex("(?m)^\\s*$(field)\\s*=\\s*\\{(.*)\\},?\\s*\$"), entry)
    return result === nothing ? nothing : strip(only(result.captures))
end

function bibtex_block(section::AbstractString)
    result = match(r"(?ms)```bibtex\s*\n(.*?)\n```", section)
    return result === nothing ? nothing : strip(only(result.captures))
end

function prose_without_bibtex(section::AbstractString)
    return replace(section, r"(?ms)```bibtex\s*\n.*?\n```" => "")
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

function check_repository(root::AbstractString = ROOT)
    failures = String[]
    warnings = String[]

    project = read_toml(root, "Project.toml")
    docs_project = read_toml(root, "docs", "Project.toml")
    benchmark_project = read_toml(root, "benchmark", "Project.toml")

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

    changelog = read_text(root, "CHANGELOG.md")
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

    citation = read_text(root, "CITATION.cff")
    source_license = read_text(root, "LICENSE")
    citation_bib = strip(read_text(root, "CITATION.bib"))
    readme = read_text(root, "README.md")
    docs_index = read_text(root, "docs", "src", "index.md")
    release_docs = read_text(root, "RELEASE.md")

    changelog_date = release_date(changelog, version)
    identifier = cff_version_identifier(citation)
    version_doi = identifier.doi
    archived_version_str = identifier.version
    archived_version =
        archived_version_str === nothing ? nothing : VersionNumber(archived_version_str)

    check!(
        failures,
        quoted_cff_value(citation, "version") == string(version),
        "CITATION.cff version must match Project.toml version $version.",
    )
    check!(
        failures,
        occursin("The QUBOTools Julia module is licensed under the MPL version 2.0:", source_license) &&
            occursin(r"(?m)^license:\s*(?:MPL-2\.0|\"MPL-2\.0\")\s*$", citation),
        "CITATION.cff license must match the MPL-2.0 source LICENSE.",
    )
    check!(
        failures,
        quoted_cff_value(citation, "doi") == CONCEPT_DOI,
        "CITATION.cff must use the concept DOI $CONCEPT_DOI as its evergreen DOI.",
    )
    check!(
        failures,
        changelog_date !== nothing && occursin(
            Regex("(?m)^date-released:\\s*(?:$(changelog_date)|\"$(changelog_date)\")\\s*\$"),
            citation,
        ),
        "CITATION.cff date-released must match the CHANGELOG.md date for v$version.",
    )
    check!(
        failures,
        version_doi !== nothing && version_doi != CONCEPT_DOI,
        "CITATION.cff must identify a distinct Zenodo version DOI.",
    )
    check!(
        failures,
        archived_version !== nothing &&
            archived_version <= version &&
            release_section(changelog, archived_version) !== nothing,
        "CITATION.cff version DOI description must reference a CHANGELOG.md version <= $version.",
    )

    if archived_version !== nothing && archived_version < version
        push!(
            warnings,
            "Exact-version citation metadata currently references v$archived_version; update CITATION.cff identifiers, CITATION.bib, README.md, and docs/src/index.md after Zenodo publishes the v$version archive.",
        )
    end

    check!(
        failures,
        preferred_citation_doi(citation) == ARTICLE_DOI,
        "CITATION.cff preferred-citation must identify the published QUBO.jl article ($ARTICLE_DOI).",
    )

    article_title = preferred_citation_title(citation)
    article_entry = bibtex_entry(citation_bib, "article")
    software_entry = bibtex_entry(citation_bib, "software")

    check!(
        failures,
        article_title !== nothing &&
            article_entry !== nothing &&
            bibtex_field(article_entry, "title") == "{$article_title}",
        "CITATION.bib @article title must match CITATION.cff preferred-citation title.",
    )

    for (entry, label, doi) in (
        (article_entry, "@article", ARTICLE_DOI),
        (software_entry, "@software", version_doi),
    )
        check!(
            failures,
            entry !== nothing && doi !== nothing && bibtex_field(entry, "doi") == doi,
            "The CITATION.bib $label entry must set doi = {$doi}.",
        )
        check!(
            failures,
            entry !== nothing &&
                doi !== nothing &&
                bibtex_field(entry, "url") == "https://doi.org/$doi",
            "The CITATION.bib $label entry must set url = {https://doi.org/$doi}.",
        )
    end

    check!(
        failures,
        software_entry !== nothing &&
            archived_version_str !== nothing &&
            bibtex_field(software_entry, "version") == "v$archived_version_str",
        "The CITATION.bib @software entry must set version = {v$archived_version_str}.",
    )
    check!(
        failures,
        software_entry !== nothing &&
            bibtex_field(software_entry, "note") == "Evergreen concept DOI: $CONCEPT_DOI",
        "The CITATION.bib @software entry must name the evergreen concept DOI $CONCEPT_DOI.",
    )

    check!(
        failures,
        occursin("badge/DOI/$CONCEPT_DOI.svg", readme) &&
            occursin("https://doi.org/$CONCEPT_DOI", readme),
        "README.md must display and link the evergreen Zenodo concept DOI badge ($CONCEPT_DOI).",
    )

    citation_start = "<!-- citation-policy:start -->"
    citation_end = "<!-- citation-policy:end -->"
    readme_citation = marked_section(readme, citation_start, citation_end)
    docs_citation = marked_section(docs_index, citation_start, citation_end)

    check!(
        failures,
        readme_citation !== nothing && readme_citation == docs_citation,
        "README.md and docs/src/index.md citation sections must remain synchronized.",
    )

    if readme_citation !== nothing
        prose = prose_without_bibtex(readme_citation)

        check!(
            failures,
            bibtex_block(readme_citation) == citation_bib,
            "The README/docs BibTeX example must match CITATION.bib.",
        )
        for doi in (CONCEPT_DOI, ARTICLE_DOI)
            check!(
                failures,
                occursin(doi, prose),
                "The synchronized citation section prose must document DOI $doi.",
            )
        end
        check!(
            failures,
            version_doi !== nothing && occursin(version_doi, prose),
            "The synchronized citation section prose must document the exact version DOI.",
        )
        check!(
            failures,
            archived_version_str !== nothing &&
                occursin("`v$archived_version_str`", prose),
            "The synchronized citation section prose must name the archived version v$archived_version_str.",
        )
    end

    maintained_citations = join((citation, citation_bib, readme, docs_index), "\n")
    for obsolete_doi in OBSOLETE_VERSION_DOIS
        check!(
            failures,
            !occursin(obsolete_doi, maintained_citations),
            "Historical version DOI $obsolete_doi must not be used by maintained citation metadata.",
        )
    end

    check!(
        failures,
        occursin(CONCEPT_DOI, release_docs) &&
            occursin("Can manage", release_docs) &&
            occursin("scripts/verify_zenodo_release.jl", release_docs),
        "RELEASE.md must document concept DOI $CONCEPT_DOI, Zenodo stewardship, and scripts/verify_zenodo_release.jl.",
    )

    return (
        failures = failures,
        warnings = warnings,
        version = version,
        expected_self_compat = expected_self_compat,
        concept_doi = CONCEPT_DOI,
        version_doi = version_doi,
    )
end

function main(root::AbstractString = ROOT)
    result = check_repository(root)

    if isempty(result.failures)
        println("Release preflight passed for QUBOTools v$(result.version).")
        println("Expected docs self-compat entry: QUBOTools = \"$(result.expected_self_compat)\".")
        println("Citation concept DOI: $(result.concept_doi).")
        println("Citation version DOI: $(result.version_doi).")
    else
        println(stderr, "Release preflight failed:")
        foreach(message -> println(stderr, "- ", message), result.failures)
    end

    if !isempty(result.warnings)
        println(stderr, "\nWarnings:")
        foreach(message -> println(stderr, "- ", message), result.warnings)
    end

    return isempty(result.failures) ? 0 : 1
end

end # module ReleaseCheck

if abspath(PROGRAM_FILE) == @__FILE__
    exit(ReleaseCheck.main())
end
