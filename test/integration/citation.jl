using Test

const __CITATION_ROOT__ = normpath(joinpath(@__DIR__, "..", ".."))

include(joinpath(__CITATION_ROOT__, "scripts", "release_check.jl"))
include(joinpath(__CITATION_ROOT__, "scripts", "verify_zenodo_release.jl"))

function _copy_citation_fixture(fn::Function)
    mktempdir() do dir
        for rel in (
            ("Project.toml",),
            ("CHANGELOG.md",),
            ("LICENSE",),
            ("CITATION.cff",),
            ("CITATION.bib",),
            ("README.md",),
            ("RELEASE.md",),
            ("docs", "Project.toml"),
            ("docs", "src", "index.md"),
            ("benchmark", "Project.toml"),
            (".github", "workflows", "zenodo.yml"),
        )
            src = joinpath(__CITATION_ROOT__, rel...)
            dst = joinpath(dir, rel...)
            mkpath(dirname(dst))
            cp(src, dst)
        end
        fn(dir)
    end
end

function _mutate_file!(dir::AbstractString, rel::Tuple, target::AbstractString, replacement::AbstractString)
    path = joinpath(dir, rel...)
    content = read(path, String)
    occursin(target, content) || error("Target string not found in $(joinpath(rel...)): $target")
    write(path, replace(content, target => replacement; count = 1))
    return nothing
end

function _zenodo_record(; concept = "7076341", version = "v0.16.2", doi = "10.5281/zenodo.23218355")
    return Dict{String,Any}(
        "conceptrecid" => concept,
        "doi" => doi,
        "metadata" => Dict{String,Any}("version" => version),
    )
end

function test_citation()
    @testset "▶ Citation & Release Verification Tests" verbose = true begin
        @testset "Repository citation metadata is consistent" begin
            result = ReleaseCheck.check_repository(__CITATION_ROOT__)
            @test isempty(result.failures)
            @test isempty(result.warnings)
            @test result.concept_doi == "10.5281/zenodo.7076341"
            @test result.version_doi == "10.5281/zenodo.23218355"

            workflow = replace(
                read(joinpath(__CITATION_ROOT__, ".github", "workflows", "zenodo.yml"), String),
                "\r\n" => "\n",
            )
            @test occursin(r"(?m)^\s*release:\s*$", workflow)
            @test occursin(r"(?m)^\s*-\s*published\s*$", workflow)
            @test occursin("scripts/verify_zenodo_release.jl", workflow)
        end

        @testset "Release preflight rejects citation drift mutations" begin
            # 1. Mismatched CITATION.cff version
            _copy_citation_fixture() do dir
                _mutate_file!(dir, ("CITATION.cff",), "version: \"0.16.2\"", "version: \"0.16.1\"")
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("CITATION.cff version must match Project.toml", f), res.failures)
            end

            # 2. Wrong CITATION.cff license
            _copy_citation_fixture() do dir
                _mutate_file!(dir, ("CITATION.cff",), "license: MPL-2.0", "license: MIT")
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("CITATION.cff license must match the MPL-2.0 source LICENSE", f), res.failures)
            end

            # 3. Wrong CITATION.cff concept DOI
            _copy_citation_fixture() do dir
                _mutate_file!(dir, ("CITATION.cff",), "doi: \"10.5281/zenodo.7076341\"", "doi: \"10.5281/zenodo.9999999\"")
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("CITATION.cff must use the concept DOI", f), res.failures)
            end

            # 4. Wrong CITATION.cff date-released
            _copy_citation_fixture() do dir
                _mutate_file!(dir, ("CITATION.cff",), "date-released: 2026-10-07", "date-released: 2026-10-08")
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("CITATION.cff date-released must match", f), res.failures)
            end

            # 5. Wrong @article DOI in CITATION.bib
            _copy_citation_fixture() do dir
                _mutate_file!(
                    dir,
                    ("CITATION.bib",),
                    "doi          = {10.1080/10556788.2026.2702926}",
                    "doi          = {10.1080/10556788.2026.0000000}",
                )
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("The CITATION.bib @article entry must set doi", f), res.failures)
            end

            # 6. Wrong @software DOI in CITATION.bib
            _copy_citation_fixture() do dir
                _mutate_file!(
                    dir,
                    ("CITATION.bib",),
                    "doi          = {10.5281/zenodo.23218355}",
                    "doi          = {10.5281/zenodo.99999999}",
                )
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("The CITATION.bib @software entry must set doi", f), res.failures)
            end

            # 7. Wrong concept DOI in @software note
            _copy_citation_fixture() do dir
                _mutate_file!(
                    dir,
                    ("CITATION.bib",),
                    "note         = {Evergreen concept DOI: 10.5281/zenodo.7076341}",
                    "note         = {Evergreen concept DOI: 10.5281/zenodo.9999999}",
                )
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("The CITATION.bib @software entry must name the evergreen concept DOI", f), res.failures)
            end

            # 8. Unsynchronized README.md and docs/src/index.md citation sections
            _copy_citation_fixture() do dir
                _mutate_file!(
                    dir,
                    ("docs", "src", "index.md"),
                    "For a direct software citation",
                    "For a package software citation",
                )
                res = ReleaseCheck.check_repository(dir)
                @test any(f -> occursin("README.md and docs/src/index.md citation sections must remain synchronized", f), res.failures)
            end

            # 9. Reintroduction of obsolete v0.10.1 or v0.11.0 version DOI
            for obsolete_doi in ("10.5281/zenodo.13879606", "10.5281/zenodo.19463565")
                _copy_citation_fixture() do dir
                    _mutate_file!(
                        dir,
                        ("README.md",),
                        "10.5281/zenodo.23218355",
                        obsolete_doi,
                    )
                    res = ReleaseCheck.check_repository(dir)
                    @test any(f -> occursin("Historical version DOI $obsolete_doi must not be used", f), res.failures)
                end
            end

            # 10. Pre-tag release preparation warning when Project.toml/CITATION.cff advance to v0.16.3
            _copy_citation_fixture() do dir
                _mutate_file!(dir, ("Project.toml",), "version = \"0.16.2\"", "version = \"0.16.3\"")
                _mutate_file!(
                    dir,
                    ("CHANGELOG.md",),
                    "# QUBOTools.jl Changelog\n",
                    "# QUBOTools.jl Changelog\n\n## v0.16.3 (2026-10-22)\n\n- Maintenance release.\n",
                )
                _mutate_file!(dir, ("CITATION.cff",), "version: \"0.16.2\"", "version: \"0.16.3\"")
                _mutate_file!(dir, ("CITATION.cff",), "date-released: 2026-10-07", "date-released: 2026-10-22")
                res = ReleaseCheck.check_repository(dir)
                @test isempty(res.failures)
                @test any(w -> occursin("Exact-version citation metadata currently references v0.16.2", w), res.warnings)
            end
        end

        @testset "Zenodo release verification detects archive drift and parses JSON" begin
            parsed = ZenodoReleaseVerification.parse_json(
                """
                {
                  "conceptrecid": "7076341",
                  "doi": "10.5281/zenodo.23218355",
                  "flag": true,
                  "empty": null,
                  "tags": ["qubo", "ising\\nmodel", "\\u03bb", "\\ud83d\\ude80"],
                  "metadata": {
                    "version": "v0.16.2",
                    "count": 24,
                    "ratio": 1.5e-2
                  }
                }
                """,
            )
            @test parsed["conceptrecid"] == "7076341"
            @test parsed["flag"] === true
            @test parsed["empty"] === nothing
            @test parsed["tags"] == Any["qubo", "ising\nmodel", "λ", "🚀"]
            @test parsed["metadata"]["version"] == "v0.16.2"
            @test parsed["metadata"]["count"] == 24
            @test parsed["metadata"]["ratio"] ≈ 0.015

            current = ZenodoReleaseVerification.check_record(_zenodo_record(), "v0.16.2")
            stale = ZenodoReleaseVerification.check_record(
                _zenodo_record(; version = "v0.16.1"),
                "v0.16.2",
            )
            wrong_concept = ZenodoReleaseVerification.check_record(
                _zenodo_record(; concept = "9999999"),
                "v0.16.2",
            )
            missing_version = ZenodoReleaseVerification.check_record(
                Dict{String,Any}("conceptrecid" => "7076341", "metadata" => Dict{String,Any}()),
                "v0.16.2",
            )

            @test current.ok
            @test current.doi == "10.5281/zenodo.23218355"
            @test !stale.ok
            @test occursin("v0.16.1", stale.message)
            @test !wrong_concept.ok
            @test occursin("9999999", wrong_concept.message)
            @test !missing_version.ok
            @test occursin("metadata.version", missing_version.message)

            responses = Any[_zenodo_record(; version = "v0.16.1"), _zenodo_record()]
            recovered = ZenodoReleaseVerification.verify_release(
                "v0.16.2";
                attempts = 2,
                delay_seconds = 0,
                record_fetcher = _ -> popfirst!(responses),
            )
            @test recovered.ok
            @test isempty(responses)

            @test_throws ErrorException ZenodoReleaseVerification.verify_release(
                "v0.16.2";
                attempts = 1,
                delay_seconds = 0,
                record_fetcher = _ -> _zenodo_record(; version = "v0.16.1"),
            )

            transport_error = try
                ZenodoReleaseVerification.verify_release(
                    "v0.16.2";
                    attempts = 1,
                    delay_seconds = 0,
                    record_fetcher = _ -> error("network unavailable"),
                )
                nothing
            catch error
                sprint(showerror, error)
            end
            @test occursin("network unavailable", transport_error)
        end
    end

    return nothing
end
