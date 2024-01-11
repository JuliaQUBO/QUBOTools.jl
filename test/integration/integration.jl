include("ext/ext.jl")
include("packages/packages.jl")

function test_integration()
    @testset "⊚ ⊚ Integration Tests" verbose = true begin
        test_extensions()
        test_packages()
    end

    return nothing
end
