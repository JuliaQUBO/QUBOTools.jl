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
        @test isfile(joinpath(__DOCS_PATH__, "build", "index.html"))
    end

    return nothing
end
