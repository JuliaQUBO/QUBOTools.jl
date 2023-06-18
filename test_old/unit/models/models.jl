include("standard.jl")

function test_models()
    @testset "⦷ Models ⦷" verbose = true begin
        test_standard()
    end
end