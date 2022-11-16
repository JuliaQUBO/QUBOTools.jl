include("bridges/bridges.jl")

function test_integration()
    @testset "◈ Integration Tests ◈" verbose = true begin
        test_bridges()
    end
end