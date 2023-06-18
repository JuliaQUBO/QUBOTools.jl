include("library/library.jl")

function test_unit()
    @testset "Unit Tests" begin
        test_library()
    end

    return nothing
end
