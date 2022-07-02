function test_bridges()
    @testset "BQPJSON -> Qubist" begin

        let qh_model, js_model
            qh_model = read(joinpath(@__DIR__, "data", "000.s.qh"), Qubist)
            js_model = read(joinpath(@__DIR__, "data", "000.s.json"), BQPJSON)
            
            @test qh_model == convert(Qubist, js_model)
        end

        let qh_model, js_model
            qh_model = read(joinpath(@__DIR__, "data", "001.s.qh"), Qubist)
            js_model = read(joinpath(@__DIR__, "data", "001.s.json"), BQPJSON)
            
            @test qh_model == convert(Qubist, js_model)
        end

        let qh_model, js_model
            qh_model = read(joinpath(@__DIR__, "data", "002.s.qh"), Qubist)
            js_model = read(joinpath(@__DIR__, "data", "002.s.json"), BQPJSON)
            
            @test qh_model == convert(Qubist, js_model)
        end
    end
end