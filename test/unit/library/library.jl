include("solution.jl")
include("form.jl")
include("model.jl")

function test_library()
    @testset "□ Library" verbose = true begin
        test_solution()
        test_form()
        test_model()
    end

    return nothing
end
