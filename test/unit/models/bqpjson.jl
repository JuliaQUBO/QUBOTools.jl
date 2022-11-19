const BQPJSON_ATOL = 1E-12

function test_bqpjson(path::String, n::Integer)
    @testset "BQPJSON" verbose = true begin
        @testset "IO" verbose = true begin
            @testset "BOOL" begin
                for i = 0:n
                    bool_path      = BQPJSON_BOOL_PATH(path, i)
                    bool_temp_path = BQPJSON_BOOL_TEMP_PATH(path, i)
                    try
                        bool_model = read(bool_path, BQPJSON)
                        @test bool_model isa BQPJSON{BoolDomain}

                        write(bool_temp_path, bool_model)

                        temp_model = read(bool_temp_path, BQPJSON)
                        @test temp_model isa BQPJSON{BoolDomain}

                        @test _isvalidbridge(
                            temp_model,
                            bool_model,
                            BQPJSON{BoolDomain},
                        )
                    catch e
                        rethrow(e)
                    finally
                        rm(bool_temp_path)
                    end
                end
            end

            @testset "SPIN" begin
                for i = 0:n
                    spin_path      = BQPJSON_SPIN_PATH(path, i)
                    spin_temp_path = BQPJSON_SPIN_TEMP_PATH(path, i)
                    try
                        spin_model = read(spin_path, BQPJSON)
                        @test spin_model isa BQPJSON{SpinDomain}

                        write(spin_temp_path, spin_model)

                        temp_model = read(spin_temp_path, BQPJSON)
                        @test temp_model isa BQPJSON{SpinDomain}

                        @test _isvalidbridge(
                            temp_model,
                            spin_model,
                            BQPJSON{BoolDomain};
                            atol = 0.0,
                        )
                    catch e
                        rethrow(e)
                    finally
                        rm(spin_temp_path; force = true)
                    end
                end
            end
        end
end