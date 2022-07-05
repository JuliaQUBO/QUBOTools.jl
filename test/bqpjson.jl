function test_bqpjson()
    @testset "BQPJSON" verbose = true begin
        @testset "BQPJSON: SPIN <--> BOOL" begin
            for i = 0:1
                bool_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.json"), BQPJSON{BoolDomain})
                spin_model = read(joinpath(@__DIR__, "data", "0$(i)", "spin.json"), BQPJSON{SpinDomain})
    
                @test isapprox(convert(BQPJSON{SpinDomain}, bool_model), spin_model; atol=1E-12)
                @test isapprox(bool_model, convert(BQPJSON{BoolDomain}, spin_model); atol=1E-12)
            end
        end
    end
end