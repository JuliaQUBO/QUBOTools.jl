function test_bqpjson_qubist()
    # Assets
    test_cases = union(QUBIST_CASES, BQPJSON_CASES)
    qubs_paths = QUBIST_PATH.(test_cases)
    spin_paths = BQPJSON_SPIN_PATH.(test_cases)

    @testset "BQPJSON → Qubist" begin
        for (qubs_path, spin_path) in zip(qubs_paths, spin_paths)
            qubs_model = read(qubs_path, Qubist{SpinDomain})
            spin_model = read(spin_path, BQPJSON{SpinDomain})

            conv_model = convert(Qubist{SpinDomain}, spin_model)

            @test _isvalidbridge(
                convert(Qubist{SpinDomain}, spin_model),
                qubs_model,
                BQPJSON{SpinDomain},
            )
            @test _isvalidbridge(
                convert(BQPJSON{SpinDomain}, qubs_model),
                spin_model,
                Qubist{SpinDomain},
            )
        end
    end

    @testset "Qubist → BQPJSON" begin
        for (qubs_path, spin_path) in zip(qubs_paths, spin_paths)
            qubs_model = read(qubs_path, Qubist)
            spin_model = read(spin_path, BQPJSON)

            @test qubs_model isa Qubist{SpinDomain}
            @test spin_model isa BQPJSON{SpinDomain}

            @test _isvalidbridge(
                convert(Qubist{SpinDomain}, spin_model),
                qubs_model,
                BQPJSON{SpinDomain},
            )
            @test _isvalidbridge(
                convert(BQPJSON{SpinDomain}, qubs_model),
                spin_model,
                Qubist{SpinDomain},
            )
        end
    end
end