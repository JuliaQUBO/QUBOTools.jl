function test_formats()
    @testset "⦷ Formats ⦷" verbose = true begin
        format_list = Type[]

        for fmt in QUBOTools.formats()
            test_cases = get(TEST_CASES, fmt, nothing)

            if isnothing(test_cases) || isempty(test_cases)
                continue
            else
                push!(format_list, fmt)
            end
        end

        for fmt in format_list
            test_cases = TEST_CASES[fmt]

            @testset "▷ $(fmt)" begin
                for i in test_cases
                    test_data_path = TEST_DATA_PATH[fmt](i)
                    temp_data_path = TEMP_DATA_PATH[fmt](i)

                    test_model = QUBOTools.read_model(test_data_path, fmt())

                    @test test_model isa QUBOTools.Model

                    QUBOTools.write_model(temp_data_path, test_model, fmt())

                    temp_model = QUBOTools.read_model(temp_data_path, fmt())

                    @test temp_model isa QUBOTools.Model
                end
            end
        end
    end
end