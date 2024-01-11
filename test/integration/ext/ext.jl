include("moi.jl")

function test_extensions()
    @testset "▶ Extensions" verbose = true begin
        test_moi()
    end

    return nothing
end