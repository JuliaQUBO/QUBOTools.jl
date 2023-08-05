function test_metrics()
    @testset "→ Metrics" verbose = true begin
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

        @testset "⋅ TTS" begin
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

    return nothing
end

function test_plots()
    @testset "→ Plots" verbose = true begin
        test_energy_frequency_plot()
        test_model_density_plot()
    end

    return nothing
end

function test_energy_frequency_plot()
    @testset "⋅ Energy Frequency" begin
        sol = SampleSet([
            Sample([0, 0], 1.0, 1),
            Sample([0, 1], 2.0, 2),
            Sample([1, 0], 3.0, 3),
            Sample([1, 1], 4.0, 4),
        ])

        p = QUBOTools.EnergyFrequencyPlot(sol)

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), p)
            @test length(r) == 1
            @test length(r[].args) == 2

            x, y = r[].args
            attr = r[].plotattributes

            @test x == [1.0, 2.0, 3.0, 4.0]
            @test y == [1, 2, 3, 4]

            @test attr[:ylabel] == "Frequency"
            @test attr[:xlabel] == "Energy"
        end
    end

    return nothing
end

function test_model_density_plot()
    @testset "⋅ Model Density" begin
        L = Dict{Int,Float64}(
            1 => 0.5,
            2 => 2.0,
            3 => -3.0,
        )
        Q = Dict{Tuple{Int,Int},Float64}(
            (1,2) => 2.0,
            (1,3) => -2.0,
            (2,3) => 0.5,
        )

        m = QUBOTools.Model{Int,Float64,Int}(L, Q; domain=:bool)
        p = QUBOTools.ModelDensityPlot(m)

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), p)
            @test length(r) == 1
            @test length(r[].args) == 3

            x, y, z = r[].args
            attr = r[].plotattributes

            @test x == [1, 2, 3]
            @test y == [1, 2, 3]
            @test z ≈ [0.5 1.0 -1.0; 1.0 2.0 0.25; -1.0 0.25 -3.0]

            @test attr[:clims] == (-3.0, 3.0)

            @test attr[:ylabel] == "Variable Index"
            @test attr[:xlabel] == "Variable Index"
        end
    end

    return nothing
end

function test_analysis()
    test_metrics()
    test_plots()

    return nothing
end