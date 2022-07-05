function test_bridges(; n::Int = 2)
    @testset "~*~ BRIDGES ~*~" verbose = true begin
    
    @testset "BQPJSON <--> Qubist" begin
        for i = 0:n
            qubs_model = read(joinpath(@__DIR__, "data", "0$(i)", "spin.qh"), Qubist)
            spin_model = read(joinpath(@__DIR__, "data", "0$(i)", "spin.json"), BQPJSON)

            @test qubs_model isa Qubist{SpinDomain}
            @test spin_model isa BQPJSON{SpinDomain}

            @test BQPIO.isapproxbridge(
                convert(Qubist{SpinDomain}, spin_model),
                qubs_model,
                BQPJSON{SpinDomain},
            )
            @test BQPIO.isapproxbridge(
                convert(BQPJSON{SpinDomain}, qubs_model),
                spin_model,
                Qubist{SpinDomain},
            )
        end
    end

    @testset "BQPJSON <--> QUBO" begin
        for i = 0:n
            qubo_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.qubo"), QUBO)
            bool_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.json"), BQPJSON)

            @test qubo_model isa QUBO{BoolDomain}
            @test bool_model isa BQPJSON{BoolDomain}

            @test BQPIO.isapproxbridge(
                convert(QUBO{BoolDomain}, bool_model),
                qubo_model,
                BQPJSON{BoolDomain},
            )
            @test BQPIO.isapproxbridge(
                convert(BQPJSON{BoolDomain}, qubo_model),
                bool_model,
                QUBO{BoolDomain},
            )
        end
    end

    end
end