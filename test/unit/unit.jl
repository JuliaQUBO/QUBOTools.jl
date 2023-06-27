include("library/library.jl")

function test_unit()
    @testset "⊚ ⊚ Unit Tests" verbose = true begin
        test_library()
    end

    return nothing
end
