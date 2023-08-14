include("model.jl")

function test_interface()
    @testset "□ Interface" verbose = true begin
        test_model_interface()
    end

    return nothing
end
