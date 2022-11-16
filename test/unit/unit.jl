include("library/library.jl")
include("models/models.jl")
# include("bridges/bridges.jl")
include("interface/interface.jl")
include("analysis/analysis.jl")


function test_unit()
    @testset "◈ Unit Tests ◈" verbose = true begin
        test_library()
        test_models()
    end
end