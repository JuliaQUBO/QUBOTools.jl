function test_error()
    @testset "Error" begin
        @test_throws QUBOTools.QUBOCodecError throw(QUBOTools.QUBOCodecError())
        @test_throws QUBOTools.SampleError throw(QUBOTools.SampleError())
    end
end