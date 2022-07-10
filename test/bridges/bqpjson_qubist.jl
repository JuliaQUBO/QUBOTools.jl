function test_bqpjson_qubist(path::AbstractString; n::Integer = 2)
    @testset "BQPJSON ~ Qubist" begin
        for i = 0:n
            qubs_model = read(joinpath(path, @sprintf("%2d", i), "spin.qh"), Qubist)
            spin_model = read(joinpath(path, @sprintf("%2d", i), "spin.json"), BQPJSON)

            @test qubs_model isa Qubist{SpinDomain}
            @test spin_model isa BQPJSON{SpinDomain}

            @test BQPIO.isvalidbridge(
                convert(Qubist{SpinDomain}, spin_model),
                qubs_model,
                BQPJSON{SpinDomain},
            )
            @test BQPIO.isvalidbridge(
                convert(BQPJSON{SpinDomain}, qubs_model),
                spin_model,
                Qubist{SpinDomain},
            )
        end
    end
end