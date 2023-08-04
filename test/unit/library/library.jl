include("solution.jl")
include("form.jl")
include("model.jl")
include("analysis.jl")

function test_library()
    @testset "□ Library" verbose = true begin
        test_solution()
        test_form()
        test_model()
        test_analysis()
    end

    return nothing
end
