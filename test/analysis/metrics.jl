function test_metrics()
    @testset "Metrics" verbose = true begin
        e = 1.0
        s = QUBOTools.SampleSet{Int,Float64}(
            QUBOTools.Sample{Int,Float64}[
                QUBOTools.Sample{Int,Float64}([0, 0, 1], 1, 1.0),
                QUBOTools.Sample{Int,Float64}([0, 1, 0], 2, 2.0),
                QUBOTools.Sample{Int,Float64}([0, 1, 1], 3, 3.0),
                QUBOTools.Sample{Int,Float64}([1, 0, 0], 4, 4.0),
            ],
            Dict{String,Any}(
                "time" => Dict{String,Any}(
                    "total"     => 2.0,
                    "effective" => 1.0
                ),
            ),
        )
        @testset "TTS" begin
            @test QUBOTools.total_time(s) == 2.0
            @test QUBOTools.effective_time(s) == 1.0

            @test QUBOTools.success_rate(s, e) ≈ 0.1 atol = 1e-8
            @test QUBOTools.tts(s, e) ≈ 43.708690653 atol = 1e-8
        end
    end
end