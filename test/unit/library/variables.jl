function test_variables()
    @testset "→ Variables" begin
        test_variable_ordering()
    end

    return nothing
end

function test_variable_ordering()
    @testset "⋅ Ordering" begin
        # Integers
        @test QUBOTools.varlt(1, 1) === false
        @test QUBOTools.varlt(1, 2) === true
        @test QUBOTools.varlt(2, 1) === false

        @test QUBOTools.varlt(1, -1) === true
        @test QUBOTools.varlt(-1, 1) === false

        # Symbols
        @test QUBOTools.varlt(:x, :x) === false
        @test QUBOTools.varlt(:x, :y) === true
        @test QUBOTools.varlt(:y, :x) === false
    end

    return nothing
end
