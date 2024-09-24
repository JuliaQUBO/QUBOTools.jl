include("ext/ext.jl")

function test_foreign()
    if run_foreign_tests()
        @testset "▶ Foreign Package Tests" verbose = true begin
            test_foreign_pkg(Pkg.PackageSpec(name="ToQUBO", rev="master"))
            test_foreign_pkg("QUBODrivers")
            test_foreign_pkg("QUBO")
        end
    end

    return nothing
end

function test_integration()
    @testset "⊚ ⊚ Integration Tests" verbose = true begin
        test_extensions()
        test_foreign()
    end

    return nothing
end
