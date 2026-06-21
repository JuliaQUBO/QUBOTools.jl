include("ext/ext.jl")
include("docs.jl")

function test_foreign()
    @testset "▶ Foreign Package Test Helpers" verbose = true begin
        test_foreign_pkg_compatibility_detection()
    end

    if run_foreign_tests()
        @testset "▶ Foreign Package Tests" verbose = true begin
            test_foreign_pkg(Pkg.PackageSpec(name="ToQUBO", rev="main"))
            test_foreign_pkg("QUBODrivers")
            test_foreign_pkg("QUBO")
        end
    end

    return nothing
end

function test_integration()
    @testset "⊚ ⊚ Integration Tests" verbose = true begin
        test_extensions()
        test_docs()
        test_foreign()
    end

    return nothing
end
