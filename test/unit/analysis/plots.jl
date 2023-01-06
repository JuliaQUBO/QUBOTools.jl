function test_plots()
    @testset "■ Plots ■" verbose = true begin
        test_sampleset_plot()
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