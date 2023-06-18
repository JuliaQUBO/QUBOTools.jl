function test_metrics()
    @testset "⦷ Metrics ⦷" verbose = true begin
        e = 1.0
        s = QUBOTools.SampleSet(
            QUBOTools.Sample{Float64,Int}[
                QUBOTools.Sample([0, 0, 1], 1.0, 1),
                QUBOTools.Sample([0, 1, 0], 2.0, 2),
                QUBOTools.Sample([0, 1, 1], 3.0, 3),
                QUBOTools.Sample([1, 0, 0], 4.0, 4),
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

            let s = QUBOTools.SampleSet()
                @test isnan(QUBOTools.total_time(s))
                @test isnan(QUBOTools.effective_time(s))
                @test isnan(QUBOTools.success_rate(s, 0.0))
                @test isnan(QUBOTools.tts(s, 0.0))
            end

            let s = QUBOTools.SampleSet(
                QUBOTools.Sample{Float64,Int}[],
                Dict{String,Any}("time" => Dict{String,Any}()),
            )
                @test isnan(QUBOTools.total_time(s))
                @test isnan(QUBOTools.effective_time(s))
                @test isnan(QUBOTools.success_rate(s, 0.0))
                @test isnan(QUBOTools.tts(s, 0.0))
            end

            let s = QUBOTools.SampleSet(
                QUBOTools.Sample{Float64,Int}[],
                Dict{String,Any}(
                    "time" => Dict{String,Any}(
                        "total" => 1.0,
                    )
                ),
            )
                @test QUBOTools.total_time(s) == 1.0
                @test QUBOTools.effective_time(s) == 1.0
                @test isnan(QUBOTools.success_rate(s, 0.0))
                @test isnan(QUBOTools.tts(s, 0.0))
            end
        end
    end
end