function test_error()
    @testset "Error" verbose = true begin
        @testset "▷ Codec" begin
            @test_throws CodecError codec_error()
            @test sprint(showerror, CodecError()) == "Codec Error"
            @test sprint(showerror, CodecError("Message!")) == "Codec Error: Message!"
        end

        @testset "▷ Sample" begin
            @test_throws SolutionError solution_error()
            @test sprint(showerror, SolutionError()) == "Sampling Error"
            @test sprint(showerror, SolutionError("Message!")) == "Sampling Error: Message!"
        end

        @testset "▷ Format" begin
            @test_throws FormatError format_error()
            @test sprint(showerror, FormatError()) == "Format Error"
            @test sprint(showerror, FormatError("Message!")) == "Format Error: Message!"
        end

        @testset "▷ Syntax" begin
            @test_throws SyntaxError syntax_error()
            @test sprint(showerror, SyntaxError()) == "Syntax Error"
            @test sprint(showerror, SyntaxError("Message!")) == "Syntax Error: Message!"
        end
    end
end