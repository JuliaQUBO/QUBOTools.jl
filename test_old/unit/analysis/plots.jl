function test_plots()
    @testset "■ Plots ■" verbose = true begin
        test_sampleset_plot()
        test_heatmap_plot()
    end
end

function test_sampleset_plot()
    @testset "SampleSet" begin
        ω = SampleSet([
            Sample([0, 0], 1.0, 1),
            Sample([0, 1], 2.0, 2),
            Sample([1, 0], 3.0, 3),
            Sample([1, 1], 4.0, 4),
        ])

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), ω)
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
end

function test_heatmap_plot()
    @testset "HeatMap" begin
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

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), m)
            @test length(r) == 1
            @test length(r[].args) == 3

            x, y, z = r[].args
            attr = r[].plotattributes

            @test x == [1, 2, 3]
            @test y == [1, 2, 3]
            @test z == [
                0.0  0.0  -3.0
                0.0  2.0   0.5
                0.5  2.0  -2.0
            ]

            @test attr[:clims] == (-3.0, 3.0)

            @test attr[:ylabel] == "Variable Index"
            @test attr[:xlabel] == "Variable Index"
        end
    end
end