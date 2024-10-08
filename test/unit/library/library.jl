include("variables.jl")
include("solution.jl")
include("form.jl")
include("model.jl")
include("analysis.jl")
include("formats.jl")

function test_library()
    @testset "□ Library" verbose = true begin
        test_variables()
        test_solution()
        test_form()
        test_model()
        test_analysis()
        test_formats()
    end

    return nothing
end
