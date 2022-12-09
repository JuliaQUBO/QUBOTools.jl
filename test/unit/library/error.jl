function test_error()
    @testset "Error" verbose = true begin
        @testset "Codec" begin
            @test_throws CodecError codec_error()
            @test sprint(showerror, CodecError()) == "Codec Error"
            @test sprint(showerror, CodecError("Message!")) == "Codec Error: Message!"
        end

        @testset "Sample" begin
            @test_throws SamplingError sampling_error()
            @test sprint(showerror, SamplingError()) == "Sampling Error"
            @test sprint(showerror, SamplingError("Message!")) == "Sampling Error: Message!"
        end
    end
end