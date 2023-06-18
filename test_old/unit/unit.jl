include("library/library.jl")
include("interface/interface.jl")
include("interface/generic.jl")
include("models/models.jl")
include("formats/formats.jl")
include("analysis/analysis.jl")


function test_unit()
    @testset "◈ Unit Tests ◈" verbose = true begin
        test_library()
        test_interface()
        test_generic()
        test_models()
        test_formats()
        test_analysis()
    end
end