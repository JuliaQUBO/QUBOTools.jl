function test_moi()
    @testset "□ MathOptInterface" begin
        # Check if the Spin variable set is defined
        @test QUBOTools.__moi_spin_set() <: MOI.AbstractScalarSet 

        # Check if the variable ordering of variables is behaving accordingly
        @test QUBOTools.varlt(VI(1), VI(1)) === false
        @test QUBOTools.varlt(VI(1), VI(2)) === true
        @test QUBOTools.varlt(VI(2), VI(1)) === false

        # This specific ordering follows as 1, 2, 3, ..., -1, -2, -3, ...
        @test_broken QUBOTools.varlt(VI(1), VI(-1)) === true
        @test_broken QUBOTools.varlt(VI(-1), VI(1)) === false
    end

    return nothing
end
