include("standard.jl")

function test_models()
    @testset "⦷ Models ⦷" verbose = true begin
        test_standard()

        model_list = Type[]

        for M in QUBOTools.models()
            test_cases = get(TEST_CASES, M, nothing)

            if isnothing(test_cases) || isempty(test_cases)
                continue
            else
                push!(model_list, M)
            end
        end

        for M in model_list
            test_cases = TEST_CASES[M]

            @testset "$(M)" begin
                for i in test_cases
                    test_data_path = TEST_DATA_PATH[M](i)
                    temp_data_path = TEMP_DATA_PATH[M](i)

                    test_model = read(test_data_path, M)

                    @test test_model isa M

                    write(temp_data_path, test_model)

                    temp_model = read(temp_data_path, M)

                    @test temp_model isa M

                    @test _isvalidbridge(temp_model, test_model, M)
                end
            end
        end
    end
end