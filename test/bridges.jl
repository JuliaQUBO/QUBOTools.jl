function test_bridges(; n::Int = 2)
    @testset "~*~ BRIDGES ~*~" verbose = true begin
    
    @testset "BQPJSON <--> Qubist" begin
        # for i = 0:n
        #     qh_model = read(joinpath(@__DIR__, "data", "00$(i).s.qh"), Qubist)
        #     js_model = read(joinpath(@__DIR__, "data", "00$(i).s.json"), BQPJSON)

        #     @test qh_model == convert(Qubist, js_model)
        #     @test qh_model == convert(Qubist, convert(BQPJSON{SpinDomain}, qh_model))
        # end
    end

    @testset "BQPJSON <--> QUBO" begin
        for i = 0:n
            qubo_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.qubo"), QUBO)
            bool_model = read(joinpath(@__DIR__, "data", "0$(i)", "bool.json"), BQPJSON)

            @test isapprox(qubo_model, convert(QUBO, bool_model))
            @test isapprox(convert(BQPJSON{BoolDomain}, qubo_model), bool_model)
        end
    end

    end
end