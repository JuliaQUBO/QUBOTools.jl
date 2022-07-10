function test_bridges(; n::Int = 2)
    @testset "~*~ BRIDGES ~*~" verbose = true begin
    
    

    @testset "BQPJSON ~ QUBO" begin
        for i = 0:n
            qubo_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.qubo"), QUBO)
            bool_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.json"), BQPJSON)

            @test qubo_model isa QUBO{BoolDomain}
            @test bool_model isa BQPJSON{BoolDomain}

            @test BQPIO.isvalidbridge(
                convert(QUBO{BoolDomain}, bool_model),
                qubo_model,
                BQPJSON{BoolDomain},
            )
            @test BQPIO.isvalidbridge(
                convert(BQPJSON{BoolDomain}, qubo_model),
                bool_model,
                QUBO{BoolDomain},
            )
        end
    end

    end
end