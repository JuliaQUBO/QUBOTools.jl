const BQPJSON_ATOL = 1E-12

function test_bqpjson(path::String; n::Integer = 2)
    @testset "BQPJSON" verbose = true begin
        @testset "BQPJSON: SPIN <--> BOOL" begin
            for i = 0:n
                bool_model = read(joinpath(path, "data", "0$(i)", "bool.json"), BQPJSON{BoolDomain})
                spin_model = read(joinpath(path, "data", "0$(i)", "spin.json"), BQPJSON{SpinDomain})
    
                @test BQPIO.isvalidbridge(
                    convert(BQPJSON{BoolDomain}, spin_model),
                    bool_model,
                    BQPJSON{SpinDomain};
                    atol = BQPJSON_ATOL
                )

                @test BQPIO.isvalidbridge(
                    convert(BQPJSON{SpinDomain}, bool_model),
                    spin_model,
                    BQPJSON{BoolDomain};
                    atol = BQPJSON_ATOL
                )
            end
        end
    end
end