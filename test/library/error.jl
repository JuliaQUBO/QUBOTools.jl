function test_error()
    @testset "Error" verbose = true begin
        @testset "QUBO Codec" begin
            @test_throws QUBOTools.QUBOCodecError QUBOTools.codec_error()

            let io = IOBuffer()
                Base.showerror(io, QUBOTools.QUBOCodecError())

                @test String(take!(io)) == "QUBO Codec Error"
            end

            let io = IOBuffer()
                Base.showerror(io, QUBOTools.QUBOCodecError("Message!"))

                @test String(take!(io)) == "QUBO Codec Error: Message!"
            end
        end

        @testset "Sample" begin
            @test_throws QUBOTools.SampleError QUBOTools.sample_error()

            let io = IOBuffer()
                Base.showerror(io, QUBOTools.SampleError())

                @test String(take!(io)) == "Sample Error"
            end

            let io = IOBuffer()
                Base.showerror(io, QUBOTools.SampleError("Message!"))

                @test String(take!(io)) == "Sample Error: Message!"
            end
        end
    end
end