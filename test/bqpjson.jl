function test_bqpjson()
    @testset "BQPJSON" verbose = true begin
        @testset "IO" begin
            model_1 = read(joinpath(@__DIR__, "data", "000.json"), BQPIO.BQPJSON)
            @test model_1 isa BQPIO.BQPJSON{BQPIO.BoolDomain}
            model_2 = convert(BQPIO.BQPJSON{BQPIO.SpinDomain}, model_1)
            @test model_2 isa BQPIO.BQPJSON{BQPIO.SpinDomain}
            model_3 = convert(BQPIO.BQPJSON{BQPIO.BoolDomain}, model_2)
            @test model_3 isa BQPIO.BQPJSON{BQPIO.BoolDomain}

            @test model_1.data == model_3.data
            
        end
    end
end