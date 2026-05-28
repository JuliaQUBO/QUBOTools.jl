using Test
using QUBOTools

const __DOCS_PATH__ = normpath(joinpath(@__DIR__, "..", "..", "docs"))

include(joinpath(__DOCS_PATH__, "build.jl"))

function test_docs()
    @testset "▶ Documentation Tests" verbose = true begin
        # Run the full docs build so docstrings and manual @example blocks stay valid.
        withenv("QUBOTOOLS_DOCS_SKIP_PLOTS" => "true") do
            build_docs(; deploy = false)
        end

        index_path = joinpath(__DOCS_PATH__, "build", "index.html")
        @test isfile(index_path)

        index_html = read(index_path, String)
        @test occursin("https://github.com/JuliaQUBO/QUBOTools.jl/blob/main/docs/src/index.md", index_html)
        @test !occursin("https://github.com/JuliaQUBO/QUBOTools.jl/blob/master/", index_html)

        manual_start_path = joinpath(__DOCS_PATH__, "build", "manual", "1-start", "index.html")
        @test isfile(manual_start_path)

        manual_start_html = read(manual_start_path, String)
        @test occursin("https://github.com/JuliaQUBO/QUBOTools.jl", manual_start_html)
        @test !occursin("https://github.com/psrenergy/QUBOTools.jl", manual_start_html)
    end

    return nothing
end
