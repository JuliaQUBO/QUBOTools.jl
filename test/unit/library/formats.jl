function test_format_hints()
    @testset "⋅ Format Hints" begin
        @test QUBOTools.format(:bool, :json) isa QUBOTools.BQPJSON
        @test QUBOTools.format("file.bool.json") isa QUBOTools.BQPJSON

        @test QUBOTools.format(:spin, :json) isa QUBOTools.BQPJSON
        @test QUBOTools.format("file.spin.json") isa QUBOTools.BQPJSON

        # @test QUBOTools.format(:hfs) isa QUBOTools.HFS
        # @test QUBOTools.format("file.hfs") isa QUBOTools.HFS

        @test QUBOTools.format(:qb) isa QUBOTools.QUBin
        @test QUBOTools.format("file.qb") isa QUBOTools.QUBin

        @test QUBOTools.format(:qh) isa QUBOTools.Qubist
        @test QUBOTools.format("file.qh") isa QUBOTools.Qubist

        @test QUBOTools.format(:qubo) isa QUBOTools.QUBO
        @test QUBOTools.format("file.qubo") isa QUBOTools.QUBO

        @test_throws Exception QUBOTools.format(:xyz)
        @test_throws Exception QUBOTools.format("file")
    end
end

function test_bqpjson_format()
    @testset "⋅ BQPJSON" begin
        @testset "bool" begin
            for i = 0:2
                file_path =
                    joinpath(__TEST_PATH__, "data", Printf.@sprintf("%02d", i), "bool.json")
                temp_path = "$(tempname()).bool.json"

                src_model = QUBOTools.read_model(file_path)

                @test src_model isa QUBOTools.Model

                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                @test dst_model isa QUBOTools.Model

                @test _compare_models(src_model, dst_model)
            end
        end

        @testset "spin" begin
            for i = 0:2
                file_path =
                    joinpath(__TEST_PATH__, "data", Printf.@sprintf("%02d", i), "spin.json")
                temp_path = "$(tempname()).spin.json"

                src_model = QUBOTools.read_model(file_path)

                @test src_model isa QUBOTools.Model

                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                @test dst_model isa QUBOTools.Model

                @test _compare_models(src_model, dst_model)
            end
        end
    end

    return nothing
end

function test_qubo_format()
    @testset "⋅ QUBO" begin
        src_fmt = QUBOTools.QUBO(:dwave)

        for i = 0:2
            file_path = joinpath(__TEST_PATH__, "data", Printf.@sprintf("%02d", i), "bool.qubo")
            temp_path = "$(tempname()).bool.qubo"

            src_model = QUBOTools.read_model(file_path, src_fmt)

            @test src_model isa QUBOTools.Model

            for dst_fmt in QUBOTools.QUBO.([:dwave, :mqlib])
                QUBOTools.write_model(temp_path, src_model, dst_fmt)

                dst_model = QUBOTools.read_model(temp_path, dst_fmt)

                @test dst_model isa QUBOTools.Model

                @test _compare_models(src_model, dst_model)
            end
        end
    end

    return nothing
end

function test_qubist_format()
    @testset "⋅ Qubist" begin
        for i = 0:2
            file_path = joinpath(__TEST_PATH__, "data", Printf.@sprintf("%02d", i), "spin.qh")
            temp_path = "$(tempname()).spin.qh"

            src_model = QUBOTools.read_model(file_path)

            @test src_model isa QUBOTools.Model

            QUBOTools.write_model(temp_path, src_model)

            dst_model = QUBOTools.read_model(temp_path)

            @test dst_model isa QUBOTools.Model

            @test _compare_models(src_model, dst_model)
        end
    end

    return nothing
end

function test_qubin_format()
    @testset "⋅ QUBin" begin
        @testset "bool" begin
            for i = 0:2
                file_path = joinpath(__TEST_PATH__, "data", Printf.@sprintf("%02d", i), "bool.qb")
                temp_path = "$(tempname()).bool.qb"

                src_model = QUBOTools.read_model(file_path)

                @test src_model isa QUBOTools.Model

                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                @test dst_model isa QUBOTools.Model

                @test _compare_models(src_model, dst_model)
            end
        end

        @testset "spin" begin
            for i = 0:2
                file_path = joinpath(__TEST_PATH__, "data", Printf.@sprintf("%02d", i), "spin.qb")
                temp_path = "$(tempname()).spin.qb"

                src_model = QUBOTools.read_model(file_path)

                @test src_model isa QUBOTools.Model

                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                @test dst_model isa QUBOTools.Model

                @test _compare_models(src_model, dst_model)
            end
        end
    end

    return nothing
end

function test_formats()
    @testset "→ Formats" verbose = true begin
        test_format_hints()
        test_bqpjson_format()
        test_qubin_format()
        test_qubo_format()
        test_qubist_format()
    end

    return nothing
end
