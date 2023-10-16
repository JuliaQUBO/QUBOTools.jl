include("variables.jl")
include("solution.jl")
include("form.jl")
include("model.jl")
include("analysis.jl")
include("formats.jl")
include("synthesis.jl")

function test_library()
    @testset "□ Library" verbose = true begin
        test_variables()
        test_solution()
        test_form()
        test_model()
        test_analysis()
        test_formats()
        test_synthesis()
    end

    return nothing
end
