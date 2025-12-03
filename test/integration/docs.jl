# Run doctests from documentation examples
# This ensures examples in the docs serve as tests for the package

import Documenter

function test_doctest()
    @testset "▶ Documentation Doctests" verbose = true begin
        doctest_result = true

        try
            # Set up doctest metadata for QUBOTools
            Documenter.DocMeta.setdocmeta!(
                QUBOTools,
                :DocTestSetup,
                :(using QUBOTools);
                recursive = true
            )

            # Run doctests for QUBOTools module
            Documenter.doctest(QUBOTools; manual = false)
        catch e
            @error "Doctest failed" exception = (e, catch_backtrace())
            @test false
            doctest_result = false
        end

        @test doctest_result
    end

    return nothing
end
