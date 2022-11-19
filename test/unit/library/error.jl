function test_error()
    @testset "Error" verbose = true begin
        @testset "Codec" begin
            @test_throws CodecError codec_error()
            @test sprint(showerror, CodecError()) == "Codec Error"
            @test sprint(showerror, CodecError("Message!")) == "Codec Error: Message!"
        end

        @testset "Sample" begin
            @test_throws SampleError sample_error()
            @test sprint(showerror, SampleError()) == "Sample Error"
            @test sprint(showerror, SampleError("Message!")) == "Sample Error: Message!"
        end
    end
end