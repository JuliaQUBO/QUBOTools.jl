 function test_bqpjson_format()
    @testset "⋅ BQPJSON" begin
        for i = 0:2
            file_path = joinpath(__TEST_PATH__, "data", @sprintf("%02d", i), "bool.json")
            temp_path = "$(tempname()).bool.json"

            src_model = QUBOTools.read_model(file_path)

            @test src_model isa QUBOTools.Model

            QUBOTools.write_model(temp_path, src_model)

            dst_model = QUBOTools.read_model(temp_path)

            @test dst_model isa QUBOTools.Model
        end
    end
    
    return nothing
end

function test_qubo_format()
    @testset "⋅ QUBO" begin
        fmt = QUBOTools.QUBO{QUBOTools.DWaveStyle}()

        for i = 0:2
            file_path = joinpath(__TEST_PATH__, "data", @sprintf("%02d", i), "bool.qubo")
            temp_path = "$(tempname()).bool.qubo"

            src_model = QUBOTools.read_model(file_path, fmt)

            @test src_model isa QUBOTools.Model

            QUBOTools.write_model(temp_path, src_model, fmt)

            dst_model = QUBOTools.read_model(temp_path, fmt)

            @test dst_model isa QUBOTools.Model
        end
    end
    
    return nothing
end

function test_qubist_format()
    @testset "⋅ Qubist" begin
        
    end
    
    return nothing
end

function test_formats()
    @testset "→ Formats" verbose = true begin
        test_bqpjson_format()
        test_qubo_format()
        test_qubist_format()
    end

    return nothing
end
