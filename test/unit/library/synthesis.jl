function test_synthesis()
    @testset "→ Synthesis" verbose = true begin
        test_wishart()
        test_sherrington_kirkpatrick()
    end

    return nothing
end

function test_wishart()
    @testset "⋅ Wishart" begin
        let n = 100
            m = 10

            model = QUBOTools.generate(QUBOTools.Wishart(n, m))

            @test QUBOTools.dimension(model) == n
            @test QUBOTools.density(model) ≈ 1.0 atol = 1E-8
            
            let sol = QUBOTools.solution(model)
                @test length(sol) > 0
            end
        end
    end

    return nothing
end

function test_sherrington_kirkpatrick()
    @testset "⋅ Sherrington-Kirkpatrick" begin
        let n = 100
            μ = 5.0
            σ = 1E-3
        
            model = QUBOTools.generate(QUBOTools.SK(n, μ, σ))
            
            @test QUBOTools.dimension(model) == n
            @test QUBOTools.density(model) ≈ 1.0 atol = 1E-8

            @test mean(last, QUBOTools.linear_terms(model))    ≈ 2μ * (1 - n) atol = 10σ
            @test mean(last, QUBOTools.quadratic_terms(model)) ≈ 4μ           atol = 10σ
        end
    end

    return nothing
end
